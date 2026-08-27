SHELL := /bin/bash

PROJECT := Input Source Pro.xcodeproj
SCHEME := Input Source Pro
CONFIG := Debug
BUILD_DIR := build
DESTINATION := platform=macOS
APP_NAME := Input Source Pro

.PHONY: help build run test dmg clean

help:
	@echo "可用指令："
	@echo "  make build   - 使用 xcodebuild 建置 App"
	@echo "  make run     - 建置並啟動 App"
	@echo "  make test    - 執行測試"
	@echo "  make dmg     - 建置簽署的 DMG（需 SIGNING_IDENTITY 與 DEVELOPMENT_TEAM）"
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

# 環境變數直接傳給 scripts/build-dmg.sh：
#   必填：SIGNING_IDENTITY、DEVELOPMENT_TEAM
#   選填：DMG_OUTPUT_DIR、CONFIG（預設 Release）、NOTARY_*（公證）
dmg:
	bash scripts/build-dmg.sh

clean:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" clean
	@rm -rf "$(BUILD_DIR)"
