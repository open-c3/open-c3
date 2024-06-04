#!/bin/bash

# 检查是否提供了足够的参数
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <namespace> <project_name> <source_branch> <target_branch>"
    exit 1
fi

# 设置变量
NAMESPACE=$1
PROJECT_NAME=$2
SOURCE_BRANCH=$3
TARGET_BRANCH=$4

# 设置变量
GITLAB_URL="http://git.xxx.com"  # GitLab 实例的 URL
GITLAB_TOKEN="xxx"       # 你的 GitLab 访问令牌
DATE=$(date)

MR_TITLE="Merge $SOURCE_BRANCH into $TARGET_BRANCH by Open-C3, Date:$DATE"  # Merge Request 标题

# 获取项目 ID
PROJECT_ID=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects?search=$PROJECT_NAME" | jq --raw-output --arg NAMESPACE "$NAMESPACE" --arg PROJECT_NAME "$PROJECT_NAME" '.[] | select(.namespace.path == $NAMESPACE and .path == $PROJECT_NAME) | .id')

if [ -z "$PROJECT_ID" ]; then
  echo "Failed to get project ID for project $NAMESPACE/$PROJECT_NAME"
  exit 1
fi

echo "Project ID for $NAMESPACE/$PROJECT_NAME is $PROJECT_ID"

# 查找现有的合并请求
EXISTING_MR=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests?state=opened&source_branch=$SOURCE_BRANCH&target_branch=$TARGET_BRANCH" | jq '.[0]')

# 提取现有合并请求的 IID
MR_IID=$(echo "$EXISTING_MR" | jq -r '.iid')

if [ "$MR_IID" == "null" ]; then
  # 创建新的 Merge Request
  MR_RESPONSE=$(curl --silent --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
      \"source_branch\": \"$SOURCE_BRANCH\",
      \"target_branch\": \"$TARGET_BRANCH\",
      \"title\": \"$MR_TITLE\"
    }" \
    "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests")

  # 提取新的 Merge Request 编号
  MR_IID=$(echo $MR_RESPONSE | jq -r '.iid')

  if [ "$MR_IID" == "null" ]; then
    echo "Failed to create Merge Request"
    echo $MR_RESPONSE
    exit 1
  fi

  echo "Created Merge Request #$MR_IID"
else
  echo "Using existing Merge Request #$MR_IID"
fi

# 合并 Merge Request
MERGE_RESPONSE=$(curl --silent --request PUT \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"merge_commit_message\": \"Merging $SOURCE_BRANCH into $TARGET_BRANCH\"
  }" \
  "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests/$MR_IID/merge")

MERGE_STATUS=$(echo $MERGE_RESPONSE | jq -r '.state')

if [ "$MERGE_STATUS" == "merged" ]; then
  echo "Successfully merged Merge Request #$MR_IID"
else
  echo "Failed to merge Merge Request"
  echo $MERGE_RESPONSE
  exit 1
fi
