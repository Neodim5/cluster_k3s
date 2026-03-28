# Шпаргалка по настройке и запуску k3s установщика

## Быстрый старт

### 1. Настройка переменных Proxmox

Откройте `terraform/proxmox.tfvars` и измените:

```hcl
# Обязательно замените на ваши значения!
proxmox_api_url = "https://192.168.1.100:8006/api2/json"
proxmox_api_token_id = "root@pam"
proxmox_api_token_secret = "YOUR_TOKEN_HERE"  # Создайте в Proxmox UI

# Укажите ваш узел и хранилище
proxmox_node = "pve"
storage_pool = "local-lvm"
network_bridge = "vmbr0"

# ID шаблона ВМ (после создания)
template_vm_id = 9000

# Ваша сеть
gateway = "192.168.1.1"
ip_range_start = "192.168.1.100"
ip_range_end = "192.168.1.200"
```

### 2. Создание шаблона ВМ в Proxmox

#### Вариант A: Ручная установка (рекомендуется для новичков)

```bash
# 1. Скачайте ISO Ubuntu
wget https://releases.ubuntu.com/jammy/ubuntu-22.04.3-live-server-amd64.iso

# 2. Загрузите ISO в Proxmox через веб-интерфейс
#    Datacenter -> local -> ISO Images -> Upload

# 3. Создайте ВМ с параметрами:
#    - VM ID: 9000
#    - CPU: 2 cores
#    - RAM: 2048 MB
#    - Disk: 10 GB
#    - Network: VirtIO, vmbr0
#    - QEMU Agent: включено

# 4. Установите Ubuntu Server
#    - Обязательно установите OpenSSH server
#    - Пользователь: ubuntu

# 5. После установки выполните в ВМ:
sudo apt update && sudo apt upgrade -y
sudo apt install -y cloud-init qemu-guest-agent python3
sudo systemctl enable qemu-guest-agent && sudo systemctl start qemu-guest-agent

# 6. Очистите и выключите:
sudo rm -f /etc/machine-id
sudo systemd-machine-id-setup --setup
sudo shutdown now

# 7. В Proxmox: Правой кнопкой по ВМ -> Convert to template
```

#### Вариант B: Готовый cloud-image (быстрее)

```bash
# На узле Proxmox выполните:
cd /var/lib/vz/template/cache
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

qm create 9000 --memory 2048 --core 2 --name ubuntu-k3s-template
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:0,import-from=/var/lib/vz/template/cache/jammy-server-cloudimg-amd64.img,discard=on
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --net0 virtio,bridge=vmbr0
qm set 9000 --agent enabled=1
qm template 9000
```

### 3. Запуск установки

```bash
# Перейдите в директорию terraform
cd terraform

# Инициализируйте Terraform
terraform init

# Проверьте план (для simple шаблона)
terraform plan -var-file="proxmox.tfvars" -var-file="templates/simple.tfvars"

# Разверните инфраструктуру
terraform apply -var-file="proxmox.tfvars" -var-file="templates/simple.tfvars"

# Дождитесь завершения и запишите IP адреса нод
```

### 4. Проверка кластера

```bash
# Подключитесь к мастер-ноде
ssh ubuntu@<MASTER_IP>

# Проверьте статус нод
kubectl get nodes

# Проверьте поды
kubectl get pods -A
```

---

## Выбор шаблона развертывания

### Simple (1 мастер + workers)
```bash
# Для разработки и тестирования
terraform apply -var-file="proxmox.tfvars" -var-file="templates/simple.tfvars"
```

**Параметры по умолчанию:**
- 1 мастер (2 CPU, 4 GB RAM, 40 GB disk)
- 2 worker (2 CPU, 4 GB RAM, 40 GB disk)
- Без HA
- Без балансировщика

### Middle (3 мастера + workers, HA)
```bash
# Для продакшн окружений
terraform apply -var-file="proxmox.tfvars" -var-file="templates/middle.tfvars"
```

**Параметры по умолчанию:**
- 3 мастера (4 CPU, 8 GB RAM, 60 GB disk)
- 3 worker (4 CPU, 8 GB RAM, 60 GB disk)
- HA включен
- Балансировщик нагрузки
- Резервное копирование
- Мониторинг

### Custom (произвольная конфигурация)
```bash
# Для специфических требований
# Отредактируйте templates/custom.tfvars перед запуском
terraform apply -var-file="proxmox.tfvars" -var-file="templates/custom.tfvars"
```

**Возможности:**
- Любое количество мастеров и workers
- Несколько пулов workers с разными характеристиками
- Выбор CNI (flannel, calico, cilium)
- Настройка безопасности
- Кастомные ingress и storage решения

---

## Yandex Cloud

Для развертывания в Yandex Cloud:

```bash
# 1. Авторизуйтесь в YC CLI
yc init

# 2. Отредактируйте terraform/yandex.tfvars
#    Укажите yc_cloud_id, yc_folder_id

# 3. Разверните
terraform apply -var-file="yandex.tfvars" -var-file="templates/simple.tfvars"
```

---

## Смена метода установки

### Ansible (по умолчанию)
```hcl
# В proxmox.tfvars или yandex.tfvars
installation_method = "ansible"
```

### k3sup
```hcl
# В proxmox.tfvars или yandex.tfvars
installation_method = "k3sup"
```

---

## Полезные команды

### Управление Terraform
```bash
# Просмотр состояния
terraform state list

# Показать конкретный ресурс
terraform state show <resource_name>

# Удалить ресурс из state (не удаляет физически)
terraform state rm <resource_name>

# Импортировать существующий ресурс
terraform import <resource_name> <resource_id>
```

### Управление кластером
```bash
# Получить kubeconfig
scp ubuntu@<MASTER_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i 's/127.0.0.1/<MASTER_IP>/g' ~/.kube/config

# Перезагрузить ноду
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
ssh ubuntu@<NODE_IP> sudo reboot
kubectl uncordon <node-name>

# Посмотреть логи k3s
journalctl -u k3s -f

# Проверить сертификаты
k3s cert rotate
```

### Удаление кластера
```bash
# Уничтожить всю инфраструктуру
terraform destroy -var-file="proxmox.tfvars" -var-file="templates/simple.tfvars"

# Принудительное удаление (если есть зависимости)
terraform destroy -var-file="proxmox.tfvars" -auto-approve
```

---

## Диагностика проблем

### Terraform не подключается к Proxmox
```bash
# Проверьте доступность API
curl -k https://<PROXMOX_IP>:8006/api2/json/version

# Проверьте токен
# Datacenter -> Permissions -> API Tokens в веб-интерфейсе Proxmox
```

### ВМ не создаются
```bash
# Проверьте наличие шаблона
# В Proxmox UI убедитесь, что шаблон с указанным ID существует

# Проверьте место на хранилище
pvesm status
```

### SSH не работает
```bash
# Проверьте cloud-init логи на ВМ
cat /var/log/cloud-init-output.log

# Проверьте SSH ключи
ssh -v ubuntu@<IP>

# Пересоздайте ВМ с правильным public key
```

### k3s не запускается
```bash
# Проверьте логи
journalctl -u k3s -f

# Проверьте порты
netstat -tlnp | grep -E '6443|2379|2380'

# Проверьте сертификат
cat /var/lib/rancher/k3s/server/tls/token
```

---

## Контакты и поддержка

- Документация k3s: https://docs.k3s.io/
- Proxmox форум: https://forum.proxmox.com/
- Terraform Proxmox Provider: https://registry.terraform.io/providers/telmate/proxmox/latest/docs
