# Yandex Cloud Master Nodes
resource "yandex_compute_instance" "masters" {
  count       = var.master_count
  name        = local.master_names[count.index]
  zone        = var.zone
  platform_id = var.platform_id

  resources {
    cores  = var.cpu_cores
    memory = var.memory_gb
  }

  boot_disk {
    initialize_params {
      image_id    = data.yandex_compute_image.ubuntu.image_id
      type        = var.disk_type
      size        = var.disk_size_gb
    }
  }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = var.external_ip
    security_group_ids = var.security_group_ids
  }

  metadata = {
    ssh-keys = "${var.user}:${file(var.ssh_public_key)}"
    user-data = <<-EOF
#!/cloud-init/config
#cloud-config
users:
  - name: ${var.user}
    ssh_authorized_keys:
      - ${file(var.ssh_public_key)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

runcmd:
  - apt-get update
  - apt-get upgrade -y
  - apt-get install -y curl wget apt-transport-https ca-certificates software-properties-common python3 python3-pip jq vim htop net-tools
  - |
    cat >> /etc/sysctl.d/k8s.conf << 'SYSCTL'
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    SYSCTL
  - sysctl --system
  - swapoff -a || true
  - sed -i '/ swap / s/^\\(.*\\)$/#!\\1/g' /etc/fstab || true
  - hostnamectl set-hostname ${local.master_names[count.index]}

hostname: ${local.master_names[count.index]}
EOF
  }

  labels = merge(
    {
      "k3s-role"    = "master"
      "environment" = "k3s-cluster"
    },
    var.tags
  )

  scheduling_policy {
    preemptible = false
  }
}

# Yandex Cloud Worker Nodes
resource "yandex_compute_instance" "workers" {
  count       = var.worker_count
  name        = local.worker_names[count.index]
  zone        = var.zone
  platform_id = var.platform_id

  resources {
    cores  = var.cpu_cores
    memory = var.memory_gb
  }

  boot_disk {
    initialize_params {
      image_id    = data.yandex_compute_image.ubuntu.image_id
      type        = var.disk_type
      size        = var.disk_size_gb
    }
  }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = var.external_ip
    security_group_ids = var.security_group_ids
  }

  metadata = {
    ssh-keys = "${var.user}:${file(var.ssh_public_key)}"
    user-data = <<-EOF
#!/cloud-init/config
#cloud-config
users:
  - name: ${var.user}
    ssh_authorized_keys:
      - ${file(var.ssh_public_key)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

runcmd:
  - apt-get update
  - apt-get upgrade -y
  - apt-get install -y curl wget apt-transport-https ca-certificates software-properties-common python3 python3-pip jq vim htop net-tools
  - |
    cat >> /etc/sysctl.d/k8s.conf << 'SYSCTL'
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    SYSCTL
  - sysctl --system
  - swapoff -a || true
  - sed -i '/ swap / s/^\\(.*\\)$/#!\\1/g' /etc/fstab || true
  - hostnamectl set-hostname ${local.worker_names[count.index]}

hostname: ${local.worker_names[count.index]}
EOF
  }

  labels = merge(
    {
      "k3s-role"    = "worker"
      "environment" = "k3s-cluster"
    },
    var.tags
  )

  scheduling_policy {
    preemptible = false
  }
}
