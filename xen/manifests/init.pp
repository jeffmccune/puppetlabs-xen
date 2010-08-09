# Class: xen
#
#   This class models the Xen Domain 0.
#
#   Virtual machines existing on the domain 0 will be modeled
#   as a puppet defined resource type.
#
#   The defined resource type must accept the hostname parameter for the
#   custom function to work properly.
#
#   Jeff McCune <jeff@puppetlabs.com>
#   2010-08-09
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class xen {
  $module = "xen"
# This defined resource type is in the class so the function
# can look it up correctly.
  define vmachine($vm_mac=false,
    $hostname=false,
    $vm_name=false,
    $vm_disk=false,
    $vm_disk_source="/dev/VolGroup00/tomcat0",
    $ensure="running",
    $vm_uuid,
    $vm_memory="512") {

  # Selections
    $module = "xen"
    $vm_name_real = $vm_name ? {
      false   => $name,
      default => $vm_name }
    $vm_disk_real = $vm_disk ? {
      false   => "/dev/VolGroup00/${vm_name_real}",
      default => $vm_disk }

  # JJM Resource Defaults
    Exec { path => "/bin:/usr/bin:/sbin:/usr/sbin" }
    File { owner => "0", group => "0", mode  => "0644" }
  # JJM Clone the GM
    file {
      "/etc/xen/${vm_name_real}":
        content => template("${module}/xenvm.erb");
    }
  # JJM FIXME The logic to create the VM is simple.  It could be more robust.
    exec {
      "lvcreate ${vm_name_real}":
        command => "lvcreate -s ${vm_disk_source} -n ${vm_name_real} -L 10G",
        creates => "${vm_disk_real}",
        require => File["/etc/xen/${vm_name_real}"];
      "xm create ${vm_name_real}":
        command => "xm create /etc/xen/${vm_name_real}",
        unless  => "xm list | grep '^${vm_name_real}'",
        require => [ File["/etc/xen/${vm_name_real}"],
                     Exec["lvcreate ${vm_name_real}"], ];
    }
  }


  # JJM Add the resources to the catalog.
  virtnodes()
}
