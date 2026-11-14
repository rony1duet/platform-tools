#!/system/bin/sh
RESETPROP="/data/adb/ksu/bin/resetprop"

# Brand and Manufacturer
$RESETPROP ro.product.brand "Redmi"
$RESETPROP ro.product.system.brand "Redmi"
$RESETPROP ro.product.system_ext.brand "Redmi"
$RESETPROP ro.product.product.brand "Redmi"
$RESETPROP ro.product.vendor.brand "Redmi"
$RESETPROP ro.product.odm.brand "Redmi"

$RESETPROP ro.product.manufacturer "Xiaomi"
$RESETPROP ro.product.system.manufacturer "Xiaomi"
$RESETPROP ro.product.system_ext.manufacturer "Xiaomi"
$RESETPROP ro.product.product.manufacturer "Xiaomi"
$RESETPROP ro.product.vendor.manufacturer "Xiaomi"
$RESETPROP ro.product.odm.manufacturer "Xiaomi"

# Name
$RESETPROP ro.product.name "sweet2"
$RESETPROP ro.product.system.name "sweet2"
$RESETPROP ro.product.system_ext.name "sweet2"
$RESETPROP ro.product.product.name "sweet2"
$RESETPROP ro.product.vendor.name "sweet2"
$RESETPROP ro.product.odm.name "sweet2"

# Model
$RESETPROP ro.product.model "Redmi Note 12 Pro"
$RESETPROP ro.product.system.model "Redmi Note 12 Pro"
$RESETPROP ro.product.system_ext.model "Redmi Note 12 Pro"
$RESETPROP ro.product.product.model "Redmi Note 12 Pro"
$RESETPROP ro.product.vendor.model "Redmi Note 12 Pro"
$RESETPROP ro.product.odm.model "Redmi Note 12 Pro"
$RESETPROP ro.product.system_dlkm.model "Redmi Note 12 Pro"
$RESETPROP ro.product.vendor_dlkm.model "Redmi Note 12 Pro"
$RESETPROP ro.product.odm_dlkm.model "Redmi Note 12 Pro"
$RESETPROP ro.product.marketname "Redmi Note 12 Pro"

# Device / Codename
$RESETPROP ro.product.device "sweet2"
$RESETPROP ro.product.system.device "sweet2"
$RESETPROP ro.product.system_ext.device "sweet2"
$RESETPROP ro.product.product.device "sweet2"
$RESETPROP ro.product.vendor.device "sweet2"
$RESETPROP ro.product.odm.device "sweet2"
$RESETPROP ro.product.system_dlkm.device "sweet2"
$RESETPROP ro.product.vendor_dlkm.device "sweet2"
$RESETPROP ro.product.odm_dlkm.device "sweet2"
$RESETPROP ro.build.product "sweet2"
$RESETPROP ro.custom.device "sweet2"

# USB String
$RESETPROP vendor.usb.product_string "Redmi Note 12 Pro"

# Settings
settings put global device_name "Redmi Note 12 Pro" 2>/dev/null || true
settings put secure bluetooth_name "Redmi Note 12 Pro" 2>/dev/null || true
settings put secure show_rotation_suggestions 0 2>/dev/null || true
