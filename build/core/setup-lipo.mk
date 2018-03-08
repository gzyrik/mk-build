$(call assert-defined, _module LIPO_ABI TARGET_OBJS NDK_APP_ABI TARGET_ARCH_ABI)

LOCAL_BUILT_MODULE := $(call module-get-built,$(_module))
LIPO_BUILT_LIBS       :=\
    $(foreach _abi,$(NDK_APP_ABI),\
        $(subst $(TARGET_ARCH_ABI),$(_abi),$(LOCAL_BUILT_MODULE)))

ifdef LIPO_BUILT_LIBS
LOCAL_BUILT_MODULE := $(notdir $(LOCAL_BUILT_MODULE))
LIPO_BUILT_MODULE := $(TARGET_OBJS)/$(LOCAL_BUILT_MODULE)
LIPO_INSTALLED := $(NDK_APP_LIBS_OUT)/$(LOCAL_BUILT_MODULE)
$(LIPO_BUILT_MODULE): PRIVATE_ABI    := $(LIPO_ABI)
$(LIPO_BUILT_MODULE): PRIVATE_NAME   := $(notdir $(LIPO_BUILT_MODULE))
$(LIPO_BUILT_MODULE): PRIVATE_CMD    := lipo -create $(LIPO_BUILT_LIBS) -output $(LIPO_BUILT_MODULE)
$(LIPO_BUILT_MODULE): $(LIPO_BUILT_LIBS)
	$(call host-echo-build-step,$(PRIVATE_ABI),UnifierLibrary) "$(PRIVATE_NAME)"
	$(hide) $(PRIVATE_CMD)
$(call generate-file-dir,$(LIPO_BUILT_MODULE))

$(LIPO_INSTALLED): PRIVATE_ABI       := $(LIPO_ABI)
$(LIPO_INSTALLED): PRIVATE_NAME      := $(notdir $(LOCAL_BUILT_MODULE))
$(LIPO_INSTALLED): PRIVATE_SRC       := $(LIPO_BUILT_MODULE)
$(LIPO_INSTALLED): PRIVATE_DST       := $(LIPO_INSTALLED)
$(LIPO_INSTALLED):$(LIPO_BUILT_MODULE) clean-installed-binaries
	$(call host-echo-build-step,$(PRIVATE_ABI),Install) "$(PRIVATE_NAME) => $(call pretty-dir,$(PRIVATE_DST))"
	$(hide) $(call host-install,$(PRIVATE_SRC),$(PRIVATE_DST))

WANTED_INSTALLED_MODULES += $(LIPO_INSTALLED)
$(call generate-file-dir,$(LIPO_INSTALLED))
endif
