# DevResourceMonitor - Personal Use Build
# =======================================

APP_NAME := DevResourceMonitor
VERSION := 1.0
BUILD_DIR := build
RELEASE_DIR := release
PROJECT_DIR := DevResourceMonitor

APP_PATH := $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app
DMG_NAME := $(APP_NAME)-$(VERSION).dmg

.PHONY: all build clean dmg run open xcodegen install-deps

all: dmg

# Show help
help:
	@echo "DevResourceMonitor Build"
	@echo "========================"
	@echo ""
	@echo "  make          - Build and create DMG"
	@echo "  make build    - Build the app only"
	@echo "  make dmg      - Build and create DMG installer"
	@echo "  make run      - Build and run the app"
	@echo "  make open     - Open project in Xcode"
	@echo "  make clean    - Remove build artifacts"
	@echo ""
	@echo "Output: $(RELEASE_DIR)/$(DMG_NAME)"

# Install dependencies
install-deps:
	@echo "Installing dependencies..."
	@which xcodegen > /dev/null || brew install xcodegen
	@echo "Done."

# Regenerate Xcode project
xcodegen:
	@cd $(PROJECT_DIR) && xcodegen generate

# Build the app
build: xcodegen
	@echo "Building $(APP_NAME)..."
	@xcodebuild -project $(PROJECT_DIR)/$(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		CODE_SIGN_IDENTITY="-" \
		-quiet
	@echo "Build complete: $(APP_PATH)"

# Create DMG
dmg: build
	@echo "Creating DMG..."
	@mkdir -p $(RELEASE_DIR)
	@rm -f $(RELEASE_DIR)/$(DMG_NAME)
	@mkdir -p $(BUILD_DIR)/dmg-contents
	@cp -R "$(APP_PATH)" $(BUILD_DIR)/dmg-contents/
	@ln -sf /Applications $(BUILD_DIR)/dmg-contents/Applications
	@hdiutil create -volname "$(APP_NAME)" \
		-srcfolder $(BUILD_DIR)/dmg-contents \
		-ov -format UDZO \
		"$(RELEASE_DIR)/$(DMG_NAME)" \
		-quiet
	@rm -rf $(BUILD_DIR)/dmg-contents
	@echo ""
	@echo "Created: $(RELEASE_DIR)/$(DMG_NAME)"
	@echo ""
	@echo "To install: Open the DMG and drag the app to Applications."
	@echo "First run: Right-click the app and select 'Open' to bypass Gatekeeper."

# Clean
clean:
	@rm -rf $(BUILD_DIR) $(RELEASE_DIR)
	@echo "Cleaned."

# Run the app
run: build
	@open "$(APP_PATH)"

# Open in Xcode
open: xcodegen
	@open $(PROJECT_DIR)/$(APP_NAME).xcodeproj
