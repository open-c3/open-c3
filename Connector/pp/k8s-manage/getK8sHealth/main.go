package main

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"github.com/huaweicloud/huaweicloud-sdk-go-v3/core/auth/basic"
	"github.com/huaweicloud/huaweicloud-sdk-go-v3/core/config"
	swr "github.com/huaweicloud/huaweicloud-sdk-go-v3/services/swr/v2"
	"github.com/huaweicloud/huaweicloud-sdk-go-v3/services/swr/v2/model"
	"gopkg.in/yaml.v3"
	"io/ioutil"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"strings"
	"time"
)

type ContainerInfo struct {
	Name              string `json:"name"`
	Image             string `json:"image"`
	ImageExistsInRepo string `json:"image_exists_in_repo"`
}

type Record struct {
	UUID           string `json:"uuid"`
	ClusterName    string `json:"cluster_name"`
	Namespace      string `json:"namespace"`
	ControllerType string `json:"type"`
	ControllerName string `json:"name"`
	ContainerName  string `json:"container_name"`
	LivenessProbe  bool   `json:"liveness_probe"`
	ReadinessProbe bool   `json:"readiness_probe"`
	StartupProbe   bool   `json:"startup_probe"`
	Image          string `json:"image"`
	ImageStatus    string `json:"image_status"`
}

type Config struct {
	AK          string `yaml:"ak"`
	SK          string `yaml:"sk"`
	HKProjectID string `yaml:"hkprojectId"`
	GZProjectID string `yaml:"gzprojectId"`
}

var cfg Config

func readConfig(filename string) error {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return err
	}

	err = yaml.Unmarshal(data, &cfg)
	if err != nil {
		return err
	}

	return nil
}

func main() {
	// 定义命令行参数
	kubeconfig := flag.String("kubeconfig", "", "Path to kubeconfig file")
	clusterName := flag.String("cluster", "default", "Name of the cluster")
	flag.Parse()

	// 加载kubeconfig配置
	config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
	if err != nil {
		panic(err)
	}

	// 读取配置文件
	err = readConfig("config.yaml")
	if err != nil {
		panic(err)
	}

	// 创建Kubernetes客户端
	client, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}

	// 获取所有命名空间
	namespaces, err := client.CoreV1().Namespaces().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		panic(err)
	}

	// 遍历所有命名空间
	for _, ns := range namespaces.Items {
		if ns.Name == "default" || ns.Name == "kube-system" || ns.Name == "kube-public" || ns.Name == "kube-flannel" || ns.Name == "monitoring" || ns.Name == "flux-system" {
			continue
		}
		// 检查Deployments
		checkController(client, *clusterName, ns.Name, "Deployment", func() ([]metav1.Object, error) {
			deployments, err := client.AppsV1().Deployments(ns.Name).List(context.TODO(), metav1.ListOptions{})
			if err != nil {
				return nil, err
			}
			objects := make([]metav1.Object, len(deployments.Items))
			for i := range deployments.Items {
				objects[i] = &deployments.Items[i]
			}
			return objects, nil
		})

		// 检查StatefulSets
		checkController(client, *clusterName, ns.Name, "StatefulSet", func() ([]metav1.Object, error) {
			statefulsets, err := client.AppsV1().StatefulSets(ns.Name).List(context.TODO(), metav1.ListOptions{})
			if err != nil {
				return nil, err
			}
			objects := make([]metav1.Object, len(statefulsets.Items))
			for i := range statefulsets.Items {
				objects[i] = &statefulsets.Items[i]
			}
			return objects, nil
		})

		// 检查DaemonSets
		checkController(client, *clusterName, ns.Name, "DaemonSet", func() ([]metav1.Object, error) {
			daemonsets, err := client.AppsV1().DaemonSets(ns.Name).List(context.TODO(), metav1.ListOptions{})
			if err != nil {
				return nil, err
			}
			objects := make([]metav1.Object, len(daemonsets.Items))
			for i := range daemonsets.Items {
				objects[i] = &daemonsets.Items[i]
			}
			return objects, nil
		})
	}
}

// checkController 检查给定集群中的控制器是否使用了指定的内部镜像。
// 它通过列出特定类型的控制器（如Deployment、StatefulSet、DaemonSet），然后检查它们的Pod模板中的容器镜像。
// 参数:
// client: Kubernetes 客户端，用于与集群通信。
// clusterName: 集群的名称。
// namespace: 控制器所在的命名空间。
// controllerType: 控制器的类型（如Deployment、StatefulSet、DaemonSet）。
// listFunc: 一个函数，用于列出特定类型的控制器。
func checkController(client *kubernetes.Clientset, clusterName, namespace, controllerType string, listFunc func() ([]metav1.Object, error)) {
	// 使用listFunc列出指定类型的控制器。
	controllers, err := listFunc()
	if err != nil {
		// 如果列出过程中出错，打印错误并返回。
		fmt.Printf("Error listing %s in namespace %s: %v\n", controllerType, namespace, err)
		return
	}

	// 遍历列出的控制器。
	for _, controller := range controllers {
		var podTemplate *corev1.PodTemplateSpec
		// 根据控制器的类型，获取Pod模板。
		switch c := controller.(type) {
		case *appsv1.Deployment:
			podTemplate = &c.Spec.Template
		case *appsv1.StatefulSet:
			podTemplate = &c.Spec.Template
		case *appsv1.DaemonSet:
			podTemplate = &c.Spec.Template
		default:
			// 如果遇到未知的控制器类型，打印警告并继续下一个控制器。
			fmt.Printf("Unknown controller type: %T\n", c)
			continue
		}

		controllerName := controller.GetName()

		// 遍历Pod模板中的每个容器。
		for _, container := range podTemplate.Spec.Containers {
			// 暂停半秒，以避免对SWR服务的请求过于频繁。
			time.Sleep(500 * time.Millisecond)
			var imageStatus string
			// 检查容器镜像是否以指定的内部镜像仓库地址开头。
			//if strings.HasPrefix(container.Image, "swr.ap-southeast-1.myhuaweicloud.com") || strings.HasPrefix(container.Image, "swr.cn-south-1.myhuaweicloud.com") {
			if strings.HasPrefix(container.Image, "swr.") {
				// 如果是内部镜像，检查该镜像在SWR中是否存在。
				//fmt.Printf("image:%s\n", container.Image)
				exists, err := checkImageExistsInSWR(container.Image)
				if err != nil {
					// 如果检查过程中出错，记录错误信息。
					//fmt.Printf("Error checking image existence for %s: %v\n", container.Image, err)
					imageStatus = "检查出错"
				} else if exists {
					// 如果镜像存在，设置状态为"存在"。
					imageStatus = "存在"
				} else {
					// 如果镜像不存在，设置状态为"不存在"。
					imageStatus = "不存在"
				}
			} else {
				imageStatus = "不是华为云镜像"
			}

			// 检查探针
			hasLivenessProbe := container.LivenessProbe != nil
			hasReadinessProbe := container.ReadinessProbe != nil
			hasStartupProbe := container.StartupProbe != nil

			// 生成一个唯一标识符。
			uuid := generateUUID(clusterName, namespace, controllerType, controllerName, container.Name)
			// 创建一个记录，包含有关控制器和容器的详细信息以及镜像状态。
			record := Record{
				UUID:           uuid,
				ClusterName:    clusterName,
				Namespace:      namespace,
				ControllerType: controllerType,
				ControllerName: controllerName,
				ContainerName:  container.Name,
				LivenessProbe:  hasLivenessProbe,
				ReadinessProbe: hasReadinessProbe,
				StartupProbe:   hasStartupProbe,
				Image:          container.Image,
				ImageStatus:    imageStatus,
			}

			// 将记录转换为JSON格式。
			jsonRecord, err := json.Marshal(record)
			if err != nil {
				// 如果转换过程中出错，记录错误并继续下一个容器。
				fmt.Printf("Error marshalling record: %v\n", err)
				continue
			}
			// 打印JSON记录。
			fmt.Println(string(jsonRecord))

		}
	}
}

func generateUUID(fields ...string) string {
	combined := strings.Join(fields, "-")
	hash := md5.Sum([]byte(combined))
	return hex.EncodeToString(hash[:])
}

func checkImageExistsInSWR(imageName string) (bool, error) {
	if !strings.HasPrefix(imageName, "swr.ap-southeast-1.myhuaweicloud.com") && !strings.HasPrefix(imageName, "swr.cn-south-1.myhuaweicloud.com") {
		return false, nil
	}

	parts := strings.SplitN(imageName, "/", 4)
	if len(parts) < 3 {
		return false, fmt.Errorf("invalid image name format: %s", imageName)
	}
	var organization, repository, targetTag string

	if len(parts) == 3 {
		organization = parts[1]
		repoAndTag := strings.SplitN(parts[2], ":", 2)
		repository = repoAndTag[0]
		targetTag = "latest"
		if len(repoAndTag) > 1 {
			targetTag = repoAndTag[1]
		}
	} else {
		organization = parts[1]
		//fmt.Printf("organization:%s\n", organization)
		repository = parts[2] + "/" + strings.SplitN(parts[3], ":", 2)[0]
		//fmt.Printf("repository:%v,%s\n", reflect.TypeOf(repository), repository)
		targetTag = strings.SplitN(parts[3], ":", 2)[1]
		//fmt.Printf("targetTag:%s\n", targetTag)
	}

	var project string
	var endpoint string
	if strings.HasPrefix(imageName, "swr.ap-southeast-1.myhuaweicloud.com") {
		project = cfg.HKProjectID
		endpoint = "https://swr-api.ap-southeast-1.myhuaweicloud.com"
	} else if strings.HasPrefix(imageName, "swr.cn-south-1.myhuaweicloud.com") {
		project = cfg.GZProjectID
		endpoint = "https://swr-api.cn-south-1.myhuaweicloud.com"
	} else {
		return false, fmt.Errorf("invalid image name format: %s", imageName)
	}
	fmt.Printf("endpoints:%s\n", endpoint)

	auth := basic.NewCredentialsBuilder().
		WithAk(cfg.AK).
		WithSk(cfg.SK).
		WithProjectId(project).
		Build()

	client := swr.NewSwrClient(
		swr.SwrClientBuilder().
			WithEndpoint(endpoint).
			WithCredential(auth).
			WithHttpConfig(config.DefaultHttpConfig()).
			Build())

	request := &model.ListRepositoryTagsRequest{}
	request.Namespace = organization
	request.Repository = repository

	//发送请求
	response, err := client.ListRepositoryTags(request)
	if err != nil {
		return false, err
	}
	if response == nil || response.Body == nil {
		return false, nil
	}
	for _, image := range *response.Body {
		if image.Tag == targetTag {
			return true, nil
		}
	}
	return true, nil
}
