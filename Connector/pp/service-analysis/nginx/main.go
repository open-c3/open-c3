package main

import (
	"bufio"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/xuri/excelize/v2"
)

type VirtualHost struct {
	IP         string              `json:"ip"`
	ServerName string              `json:"server_name"`
	Domain     string              `json:"domain"`
	Locations  []Location          `json:"locations"`
	Upstreams  map[string][]string `json:"upstreams"`
	FilePath   string              `json:"file_path"`
}

type Location struct {
	Path      string `json:"path"`
	ProxyPass string `json:"proxy_pass"`
	Upstream  string `json:"upstream"`
}

type SimplifiedVHost struct {
	IP         string `json:"ip"`
	ServerName string `json:"server_name"`
	Path       string `json:"path"`
	Upstream   string `json:"upstream"`
	ProxyPass  string `json:"proxy_pass"`
	UUID       string `json:"uuid"`
}

func main() {
	//rootDir := "nginx" // 替换为实际的nginx配置文件根目录
	//vhosts := processDirectory(rootDir)
	// 检查命令行参数
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run main.go <nginx_config_directory>")
		os.Exit(1)
	}

	rootDir := os.Args[1] // 从命令行参数获取nginx配置文件根目录

	// 打印nginx配置信息
	//printNginxConfig(rootDir)
	// 创建Excel文件
	//createExcelFile(vhosts)

	// 创建JSON文件
	//createJSONFile(vhosts)

	//打印nginx配置信息
	printNginxconfig(rootDir)
}

func createExcelFile(vhosts []VirtualHost) {
	f := excelize.NewFile()
	sheet := "Sheet1"
	now := time.Now()
	formatdate := now.Format("20060102150405")
	// 写入表头
	headers := []string{"IP", "Server Name", "Domain", "Location", "Proxy Pass", "Upstream", "Upstream Servers", "File Path"}
	for i, header := range headers {
		cell, _ := excelize.CoordinatesToCellName(i+1, 1)
		f.SetCellValue(sheet, cell, header)
	}

	// 写入数据
	row := 2
	for _, vhost := range vhosts {
		for _, loc := range vhost.Locations {
			upstreamServers := strings.Join(vhost.Upstreams[loc.Upstream], ", ")
			data := []interface{}{
				vhost.IP,
				vhost.ServerName,
				vhost.Domain,
				loc.Path,
				loc.ProxyPass,
				loc.Upstream,
				upstreamServers,
				vhost.FilePath,
			}
			for i, value := range data {
				cell, _ := excelize.CoordinatesToCellName(i+1, row)
				f.SetCellValue(sheet, cell, value)
			}
			row++
		}
	}

	// 保存Excel文件
	if err := f.SaveAs("nginx_config_" + fmt.Sprintf(formatdate) + ".xlsx"); err != nil {
		fmt.Println("Error saving Excel file:", err)
	}
}

func createJSONFile(vhosts []VirtualHost) {
	jsonData, err := json.MarshalIndent(vhosts, "", "  ")
	if err != nil {
		fmt.Println("Error marshalling JSON:", err)
		return
	}

	err = os.WriteFile("nginx_config.json", jsonData, 0644)
	if err != nil {
		fmt.Println("Error writing JSON file:", err)
		return
	}

	fmt.Println("JSON file created successfully: nginx_config.json")
}

func generateUUID(ip, serverName, path string) string {
	data := ip + serverName + path
	hash := md5.Sum([]byte(data))
	return hex.EncodeToString(hash[:])
}
func processDirectory(rootDir string) []VirtualHost {
	var vhosts []VirtualHost

	// 获取第一层目录
	firstLevelDirs, err := os.ReadDir(rootDir)
	if err != nil {
		fmt.Println("Error reading root directory:", err)
		return vhosts
	}

	for _, dir := range firstLevelDirs {
		if dir.IsDir() {
			ip := dir.Name()
			dirPath := filepath.Join(rootDir, ip)

			err := filepath.Walk(dirPath, func(path string, info os.FileInfo, err error) error {
				if err != nil {
					return err
				}

				if !info.IsDir() && strings.HasSuffix(info.Name(), ".conf") {
					vhost := processFile(path, ip)
					vhosts = append(vhosts, vhost)

					// 打印每个文件的JSON到标准输出，压缩成一行
					//jsonData, err := json.Marshal(vhost)
					//if err != nil {
					//	fmt.Println("Error marshalling JSON for file:", path, err)
					//} else {
					//	fmt.Println(string(jsonData))
					//}
				}

				return nil
			})

			if err != nil {
				fmt.Println("Error walking through directory:", err)
			}
		}
	}

	return vhosts
}

func processFile(filePath, ip string) VirtualHost {
	file, err := os.Open(filePath)
	if err != nil {
		fmt.Println("Error opening file:", err)
		return VirtualHost{}
	}
	defer file.Close()

	vhost := VirtualHost{
		IP:        ip,
		Upstreams: make(map[string][]string),
		FilePath:  filePath,
	}

	scanner := bufio.NewScanner(file)
	var currentLocation *Location
	var currentUpstream string
	inUpstreamBlock := false

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		if strings.HasPrefix(line, "server_name") {
			vhost.ServerName = extractValue(line)
			vhost.Domain = extractDomain(vhost.ServerName)
		} else if strings.HasPrefix(line, "location") {
			if currentLocation != nil {
				vhost.Locations = append(vhost.Locations, *currentLocation)
			}
			currentLocation = &Location{Path: extractLocationPath(line)}
		} else if strings.HasPrefix(line, "proxy_pass") && currentLocation != nil {
			currentLocation.ProxyPass = extractValue(line)
			currentLocation.Upstream = extractUpstreamName(currentLocation.ProxyPass)
		} else if strings.HasPrefix(line, "upstream") {
			currentUpstream = extractUpstreamName(line)
			inUpstreamBlock = true
		} else if strings.HasPrefix(line, "}") && inUpstreamBlock {
			inUpstreamBlock = false
		} else if strings.HasPrefix(line, "server") && inUpstreamBlock {
			server := extractServerValue(line)
			vhost.Upstreams[currentUpstream] = append(vhost.Upstreams[currentUpstream], server)
		}
	}

	//fmt.Println(vhost.Upstreams)
	if currentLocation != nil {
		vhost.Locations = append(vhost.Locations, *currentLocation)
	}

	return vhost
}

func printNginxconfig(rootDir string) {
	// 用于存储所有 upstream 信息的 map
	allUpstreams := make(map[string][]string)

	// 第一次遍历：收集所有的 upstream 信息
	collectUpstreams(rootDir, allUpstreams)

	// 第二次遍历：处理每个虚拟主机配置
	processVhosts(rootDir, allUpstreams)
}

func collectUpstreams(rootDir string, allUpstreams map[string][]string) {
	filepath.Walk(rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && strings.HasSuffix(info.Name(), ".conf") {
			file, err := os.Open(path)
			if err != nil {
				fmt.Println("Error opening file:", err)
				return nil
			}
			defer file.Close()

			scanner := bufio.NewScanner(file)
			var currentUpstream string
			inUpstreamBlock := false

			for scanner.Scan() {
				line := strings.TrimSpace(scanner.Text())

				if strings.HasPrefix(line, "upstream") {
					currentUpstream = extractUpstreamName(line)
					inUpstreamBlock = true
				} else if strings.HasPrefix(line, "}") && inUpstreamBlock {
					inUpstreamBlock = false
				} else if strings.HasPrefix(line, "server") && inUpstreamBlock {
					server := extractServerValue(line)
					allUpstreams[currentUpstream] = append(allUpstreams[currentUpstream], server)
				}
			}
		}
		return nil
	})
}

func processVhosts(rootDir string, allUpstreams map[string][]string) {
	filepath.Walk(rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && strings.HasSuffix(info.Name(), ".conf") {
			// 获取相对于 rootDir 的路径
			relPath, err := filepath.Rel(rootDir, path)
			if err != nil {
				fmt.Println("Error getting relative path:", err)
				return nil
			}

			// 分割路径，第一个元素应该是 IP
			pathParts := strings.Split(relPath, string(os.PathSeparator))
			if len(pathParts) < 2 {
				fmt.Println("Invalid path structure:", path)
				return nil
			}

			ip := pathParts[0] // 第一个目录名作为 IP

			vhost := processFile(path, ip)

			//vhost := processFile(path, filepath.Base(filepath.Dir(path)))

			for _, location := range vhost.Locations {
				upstreamStr := ""
				proxyPass := location.ProxyPass

				// 检查 proxy_pass 是否是一个 upstream 名称
				if strings.HasPrefix(proxyPass, "http://") {
					upstreamName := strings.TrimPrefix(proxyPass, "http://")
					if upstream, ok := allUpstreams[upstreamName]; ok {
						upstreamStr = strings.Join(upstream, ",")
						proxyPass = upstreamName // 保持原始的 upstream 名称
					} else {
						// 如果在 allUpstreams 中找不到对应的 upstream，
						// 则将 http:// 后面的内容设置为 upstream
						upstreamStr = upstreamName
					}
				} else {
					// 如果 proxy_pass 不是以 "http://" 开头，假设它是一个 upstream 名称
					if upstream, ok := allUpstreams[proxyPass]; ok {
						upstreamStr = strings.Join(upstream, ",")
					} else {
						// 如果在 allUpstreams 中找不到对应的 upstream，
						// 则将整个 proxyPass 设置为 upstream
						upstreamStr = proxyPass
					}
				}

				simplifiedVHost := SimplifiedVHost{
					IP:         vhost.IP,
					ServerName: vhost.ServerName,
					Path:       location.Path,
					Upstream:   upstreamStr,
					ProxyPass:  proxyPass,
					UUID:       generateUUID(vhost.IP, vhost.ServerName, location.Path),
				}

				jsonData, err := json.Marshal(simplifiedVHost)
				if err != nil {
					fmt.Println("Error marshalling JSON for file:", path, err)
				} else {
					fmt.Println(string(jsonData))
				}
			}
		}
		return nil
	})
}

func extractValue(line string) string {
	parts := strings.Fields(line)
	if len(parts) > 1 {
		return strings.Trim(parts[1], ";")
	}
	return ""
}

func extractLocationPath(line string) string {
	re := regexp.MustCompile(`location\s+([^{]+)`)
	matches := re.FindStringSubmatch(line)
	if len(matches) > 1 {
		return strings.TrimSpace(matches[1])
	}
	return ""
}

func extractUpstreamName(line string) string {
	re := regexp.MustCompile(`(?:upstream|http://)\s*([^ ;]+)`)
	matches := re.FindStringSubmatch(line)
	if len(matches) > 1 {
		return matches[1]
	}
	return ""
}

func extractProxyPass(proxyPass string) string {
	re := regexp.MustCompile(`http://([^;]+)`)
	matches := re.FindStringSubmatch(proxyPass)
	if len(matches) > 1 {
		return matches[1]
	}
	return ""
}

func extractServerValue(line string) string {
	re := regexp.MustCompile(`server\s+([^;]+)`)
	matches := re.FindStringSubmatch(line)
	if len(matches) > 1 {
		return strings.TrimSpace(matches[1])
	}
	return ""
}

func extractDomain(serverName string) string {
	parts := strings.Split(serverName, ".")
	if len(parts) >= 2 {
		return strings.Join(parts[len(parts)-2:], ".")
	}
	return serverName
}
