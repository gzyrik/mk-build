ifeq (,$(call set_is_member,$(__java_modules),$(LOCAL_MODULE)))
__java_modules := $(call set_insert,$(__java_modules),$(LOCAL_MODULE))

LOCAL_BUILD_SCRIPT := PREBUILT_JAVA_LIBRARY
LOCAL_MODULE_CLASS := PREBUILT_JAVA_LIBRARY
LOCAL_MAKEFILE     := $(local-makefile)

LOCAL_PREBUILT_PREFIX := lib
LOCAL_PREBUILT_SUFFIX := $(TARGET_JAR_EXTENSION)

# Prebuilt static libraries don't need to be copied to TARGET_OUT
# to facilitate debugging, so use the prebuilt version directly
# at link time.
LOCAL_BUILT_MODULE := $(call local-prebuilt-path,$(LOCAL_SRC_FILES))
LOCAL_BUILT_MODULE_NOT_COPIED := true

include $(BUILD_SYSTEM)/prebuilt-library.mk
endif
