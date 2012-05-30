COMMON_CONF = apache-credit

CREDIT_LOCATION = ~ "^/(?!(.*dashboard|.*concrete/js/tiny_mce))"

include $(FAB_PATH)/common/mk/turnkey/lamp.mk
include $(FAB_PATH)/common/mk/turnkey.mk
