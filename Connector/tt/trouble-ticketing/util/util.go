package util

import "reflect"

func RemoveDuplicateStr(strSlice []string) []string {
	allKeys := make(map[string]bool)
	var list []string
	for _, item := range strSlice {
		if _, value := allKeys[item]; !value {
			allKeys[item] = true
			list = append(list, item)
		}
	}
	return list
}

func ConvertStructInterToMap(i interface{}) map[string]interface{} {
	val := reflect.ValueOf(i).Elem()
	typ := val.Type()

	m := make(map[string]interface{})
	for index := 0; index < val.NumField(); index++ {
		m[typ.Field(index).Name] = val.Field(index).Interface()
	}
	return m
}
