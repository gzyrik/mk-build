ifeq (,$(call set_is_member,$(__java_modules),$(LOCAL_MODULE)))
__java_modules := $(call set_insert,$(__java_modules),$(LOCAL_MODULE))

LOCAL_BUILD_SCRIPT := BUILD_JAVA_LIBRARY
LOCAL_MAKEFILE     := $(local-makefile)


$(call check-defined-LOCAL_MODULE,$(LOCAL_BUILD_SCRIPT))
$(call check-LOCAL_MODULE,$(LOCAL_MAKEFILE))
$(call check-LOCAL_MODULE_FILENAME)

$(call handle-module-filename,,$(TARGET_JAR_EXTENSION))

#$(call handle-module-built)
LOCAL_BUILT_MODULE := $(JAVA_OBJS)/$(LOCAL_MODULE_FILENAME)
LOCAL_OBJS_DIR     := $(JAVA_OUT)/$(LOCAL_MODULE)

LOCAL_MODULE_CLASS := JAVA_LIBRARY
include $(BUILD_SYSTEM)/build-module.mk
#--------------------------------------------
$(call assert-defined, LOCAL_MODULE LOCAL_INSTALLED LOCAL_BUILT_MODULE)
$(call generate-file-dir,$(LOCAL_BUILT_MODULE))
$(call generate-file-dir,$(LOCAL_INSTALLED))

.PHONY: $(LOCAL_MODULE)
$(LOCAL_MODULE): $(LOCAL_BUILT_MODULE)

LOCAL_SRC_FILES := $(foreach __f,$(LOCAL_SRC_FILES),\
    $(if $(call host-path-is-absolute, $(__f)),\
        $(__f),\
        $(addprefix $(LOCAL_PATH)/, $(__f))))
LOCAL_OBJECTS := $(filter %.jar,$(LOCAL_SRC_FILES))
LOCAL_SRC_FILES := $(filter %.java,$(LOCAL_SRC_FILES))

$(LOCAL_BUILT_MODULE): PRIVATE_ABI 		 := java
$(LOCAL_BUILT_MODULE): PRIVATE_NAME      := $(notdir $(LOCAL_BUILT_MODULE))
$(LOCAL_BUILT_MODULE): PRIVATE_PKG_RENAME:= $(LOCAL_PACKAGE_RENAME)
$(LOCAL_BUILT_MODULE): PRIVATE_SRC_FILES := $(LOCAL_SRC_FILES)
$(LOCAL_BUILT_MODULE): PRIVATE_JAR_FILES := $(LOCAL_OBJECTS)
$(LOCAL_BUILT_MODULE): PRIVATE_OBJ_DIR   := $(LOCAL_OBJS_DIR)
$(LOCAL_BUILT_MODULE): PRIVATE_CLS_DIR   := $(JAVA_OBJS)/classes
$(LOCAL_BUILT_MODULE): PRIVATE_JAVA_FLAGS:= $(LOCAL_CFLAGS) \
	$(if $(filter debug,$(NDK_APP_OPTIM)), -g) -d $(PRIVATE_CLS_DIR) \
	-cp $(call merge,:,$(PRIVATE_JAR_FILES) $(NDK_ROOT)/android.jar $(LOCAL_JAVA_CLASS_PATH))
	
$(LOCAL_BUILT_MODULE): PRIVATE_JARX_CMD := cd $(PRIVATE_CLS_DIR) \
	$(foreach __f,$(PRIVATE_JAR_FILES),&& jar xf $(notdir $(__f))) \
	&& $(call host-rm, $(notdir $(PRIVATE_JAR_FILES)))

$(LOCAL_BUILT_MODULE): $(LOCAL_OBJECTS) $(LOCAL_SRC_FILES) $(LOCAL_MAKEFILE) $(NDK_APP_APPLICATION_MK)
	$(call host-echo-build-step,$(PRIVATE_ABI),Compile++ java) "$(notdir $(PRIVATE_SRC_FILES))"
	$(hide) $(call host-rm,$@)
	$(hide)$(call host-mkdir,$(PRIVATE_CLS_DIR))
ifdef LOCAL_SRC_FILES
ifdef LOCAL_PACKAGE_RENAME
	$(hide)$(call host-mkdir,$(PRIVATE_OBJ_DIR))
	$(hide)lua $(NDK_ROOT)/ndk-gsub.lua $(PRIVATE_PKG_RENAME) $(PRIVATE_SRC_FILES) -d $(PRIVATE_OBJ_DIR)
	$(hide)javac $(PRIVATE_JAVA_FLAGS) $(addprefix $(PRIVATE_OBJ_DIR)/,$(notdir $(PRIVATE_SRC_FILES)))
else
	$(hide)javac $(PRIVATE_JAVA_FLAGS) $(PRIVATE_SRC_FILES)
endif
endif
ifdef LOCAL_OBJECTS
	$(hide)$(call host-cp,$(PRIVATE_JAR_FILES),$(PRIVATE_CLS_DIR))
	$(hide)$(PRIVATE_JARX_CMD)
endif
	$(hide)jar cf $@ -C $(PRIVATE_CLS_DIR) .
	$(hide)$(call host-rmdir,$(PRIVATE_CLS_DIR))

$(LOCAL_INSTALLED): PRIVATE_ABI 	  	:= java
$(LOCAL_INSTALLED): PRIVATE_SRC         := $(LOCAL_BUILT_MODULE)
$(LOCAL_INSTALLED): PRIVATE_NAME      	:= $(notdir $(LOCAL_BUILT_MODULE))
$(LOCAL_INSTALLED): PRIVATE_DST         := $(LOCAL_INSTALLED)
$(LOCAL_INSTALLED): $(LOCAL_BUILT_MODULE) clean-installed-binaries
	$(call host-echo-build-step,$(PRIVATE_ABI),Install) "$(PRIVATE_NAME) => $(call pretty-dir,$(PRIVATE_DST))"
	$(hide) $(call host-install,$(PRIVATE_SRC),$(PRIVATE_DST))

cleantarget := clean-$(LOCAL_MODULE)
.PHONY: $(cleantarget)
clean: $(cleantarget)

$(cleantarget): PRIVATE_ABI         := java
$(cleantarget): PRIVATE_MODULE      := $(LOCAL_MODULE)
$(cleantarget): PRIVATE_CLEAN_FILES := $(LOCAL_BUILT_MODULE) $(LOCAL_OBJS_DIR) $(JAVA_OBJS)/classes
$(cleantarget)::
	$(call host-echo-build-step,$(PRIVATE_ABI),Clean) "$(PRIVATE_MODULE) [$(PRIVATE_ABI)]"
	$(hide) $(call host-rmdir,$(PRIVATE_CLEAN_FILES))
endif
