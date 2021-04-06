package devkit

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math/rand"
	"strconv"
	"strings"
	"time"

	logrus "github.com/sirupsen/logrus"
)

// JSONS marshal i to string json
func JSONS(i interface{}) string {
	bt, err := json.Marshal(i)
	if err != nil {
		logrus.Error(err)
	}
	return string(bt)
}

// JSON marshal i to []byte json
func JSON(i interface{}) []byte {
	bt, err := json.Marshal(i)
	if err != nil {
		logrus.Error(err)
	}
	return bt
}

// Offset calculate offset from page & size
func Offset(page, size int) (offset int) {
	if page < 1 {
		return 0
	}
	offset = (page - 1) * size
	return
}

// Size default return to one
func Size(size int) int {
	if size < 1 {
		return 1
	}
	return size
}

// SizeWithLimit if size lower/greater than the limit
// it will return the limit
func SizeWithLimit(limit, size int) int {
	if size < 1 || size > limit {
		return limit
	}
	return size
}

// Page default return to one
func Page(page int) int {
	if page < 1 {
		return 1
	}
	return page
}

// FatalErr fatal if err not nil
func FatalErr(err error) {
	if err != nil {
		logrus.Fatal(err)
	}
}

// MD5HashUnique hash plain+timestamp to make it unique
func MD5HashUnique(plain string) string {
	h := md5.New()
	timestamp := fmt.Sprint(time.Now().UnixNano())
	_, _ = h.Write([]byte(plain + timestamp))
	return hex.EncodeToString(h.Sum(nil))
}

// UniqueInt default max to 999
func UniqueInt(max int) int {
	if max < 1 {
		max = 999
	}
	rand.Seed(time.Now().UnixNano())
	return rand.Intn(max)
}

// Int64ToString ..
func Int64ToString(n int64) string {
	return fmt.Sprint(n)
}

// IntToString ..
func IntToString(n int) string {
	return fmt.Sprint(n)
}

// StringToInt64 if s is not an int64, will return 0
func StringToInt64(s string) int64 {
	i, err := strconv.ParseInt(s, 10, 64)
	if err != nil {
		return 0
	}
	return i
}

//  StringToInt64 if s is not an int, will return 0
func StringToInt(s string) int {
	val, err := strconv.Atoi(s)
	if err != nil {
		return 0
	}
	return val
}

// StringToBool ..
func StringToBool(s string) bool {
	return strings.ToLower(s) == "true"
}

// BoolP to pointer
func BoolP(b bool) *bool {
	return &b
}

// StringP to pointer
func StringP(s string) *string {
	return &s
}

// IntP to pointer
func IntP(i int) *int {
	return &i
}

// Int64P to pointer
func Int64P(i int64) *int64 {
	return &i
}

// Float64P to pointer
func Float64P(f float64) *float64 {
	return &f
}
