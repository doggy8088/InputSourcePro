SHELL := /bin/bash

PROJECT := Input Source Pro.xcodeproj
SCHEME := Input Source Pro
CONFIG := Debug
BUILD_DIR := build
DESTINATION := platform=macOS
APP_NAME := Input Source Pro

.PHONY: help build run test clean

help:
	@echo "可用指令："
	@echo "  make build   - 使用 xcodebuild 建置 App"
	@echo "  make run     - 建置並啟動 App"
	@echo "  make test    - 執行測試"
	@echo "  make clean   - 清除建置快取"

build:
	xcodebuild -project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIG)" \
		-derivedDataPath "$(BUILD_DIR)" \
		build

run: build
	@open "$(BUILD_DIR)/Build/Products/$(CONFIG)/$(APP_NAME).app"

test:
	xcodebuild -project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIG)" \
		-destination "$(DESTINATION)" \
		test

clean:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" clean
	@rm -rf "$(BUILD_DIR)"
