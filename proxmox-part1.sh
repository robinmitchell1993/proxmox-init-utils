#!/bin/bash
set -u

# =================================================================================================
# Update Proxmox and automatically upgrade everything
#
echo "========================================"
echo "UPDATE PROXMOX"
echo "========================================"
apt update && apt upgrade -y
apt install ipmitool -y
apt install git -y
git clone https://github.com/robinmitchell1993/proxmox-init-utils/
mv proxmox-init-utils/backup_identify.py /root/
mv proxmox-init-utils/proxmox-part2.sh /root/
mv proxmox-init-utils/power-man.sh /root/


# =================================================================================================
# Create Fan Cron Job
#
echo "========================================"
echo "ADDING POWER MAN CRON JOB"
echo "========================================"
crontab -l > mycron
echo "* * * * * /bin/bash /root/power-man.sh >> /var/log/power-man.log 2&>1" >> mycron
crontab mycron
rm mycron


# =================================================================================================
# Configure IOMMU
echo "========================================"
echo "CONFIGURE IOMMU"
echo "========================================"
SEARCH="GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\""
REPLACE="GRUB_CMDLINE_LINUX_DEFAULT=\"quiet intel_iommu=on iommu=pt pcie_acs_override=downstream,multifunction nofb nomodeset video=vesafb:off,efifb:off\""
sed -i 's/$SEARCH/$REPLACE/' /etc/default/grub
update-grub


# =================================================================================================
# Passthrough GPU
echo "========================================"
echo "Handling VFIO"
echo "========================================"
echo vfio >> /etc/modules
echo vfio_iommu_type1 >> /etc/modules
echo vfio_pci >> /etc/modules
echo vfio_virqfd >> /etc/modules

echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf


# =================================================================================================
# Get Vendor IDs for NVIDIA GPUs
echo "========================================"
echo "Handling GPU VENDORS"
echo "========================================"
lspci > "pci_devices.txt"
grep NVIDIA pci_devices.txt > gpu_match.txt
grep -o "[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]" gpu_match.txt > gpu_extract.txt

cat < gpu_id_codes.txt

# Grab the PCIe Number
while IFS= read -r line; do
    lspci -n -s $line | awk '{print $3}' >> gpu_id_codes.txt
done < gpu_extract.txt

# Eliminate identical entries
sort gpu_id_codes.txt|uniq > output.txt

# Now add them to the options
OPTIONS=""

while IFS= read -r line; do
        if [ -z "$OPTIONS" ]; then
                OPTIONS="${line}"
        else
                OPTIONS="${OPTIONS},${line}"
        fi
done < output.txt

echo "options vfio-pci ids=${OPTIONS} disable_vga=1"> /etc/modprobe.d/vfio.conf

rm output.txt
rm gpu_id_codes.txt
rm gpu_extract.txt
rm gpu_match.txt
rm pci_devices.txt

echo update-initramfs -u

# Prep for script part 2 to run
chmod a+x /root/proxmox-part2.sh
crontab -l > mycron
echo "@reboot /bin/bash /root/proxmox-part2.sh" >> mycron
crontab mycron
rm mycron

reboot now