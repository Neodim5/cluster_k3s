# Руководство по настройке и запуску установщика k3s

Это руководство описывает все необходимые шаги для подготовки инфраструктуры, создания шаблона ВМ и запуска установки кластера k3s.

## Содержание

1. [Настройка переменных Terraform](#1-настройка-переменных-terraform)
2. [Создание шаблона ВМ в Proxmox VE](#2-создание-шаблона-вм-в-proxmox-ve)
3. [Запуск установки кластера](#3-запуск-установки-кластера)
4. [Проверка результата](#4-проверка-результата)
5. [Устранение неполадок](#5-устранение-неполадок)

---

## 1. Настройка переменных Terraform

### 1.1. Структура файлов переменных

Файлы переменных находятся в директории `terraform/`:
- `proxmox.tfvars` - переменные для развертывания в Proxmox VE
- `yandex.tfvars` - переменные для развертывания в Yandex Cloud
- `templates/simple.tfvars`, `templates/middle.tfvars`, `templates/custom.tfvars` - шаблоны конфигурации кластера

### 1.2. Настройка Proxmox VE (proxmox.tfvars)

Откройте файл `terraform/proxmox.tfvars` и заполните следующие параметры:

```hcl
# === Общие настройки провайдера ===

# Адрес API Proxmox VE (например, https://192.168.1.100:8006/api2/json)
proxmox_api_url = "https://<IP_АДРЕС_PROXMOX>:8006/api2/json"

# Имя пользователя для API (формат: username@realm, например, root@pam)
proxmox_api_token_id = "root@pam"

# Токен API (создается в интерфейсе Proxmox: Datacenter -> Permissions -> API Tokens)
proxmox_api_token_secret = "ВАШ_ТОКЕН"

# Отключить проверку SSL сертификата (для самоподписанных сертификатов)
proxmox_tls_insecure = true


# === Настройки окружения ===

# Идентификатор узла Proxmox (например, "pve", "node1" и т.д.)
proxmox_node = "pve"

# ID хранилища для облачных образов (обычно "local" или "local-lvm")
storage_pool = "local"

# Сетевой мост для подключения ВМ
network_bridge = "vmbr0"


# === Шаблон ВМ ===

# ID шаблона ВМ (создается на следующем этапе)
template_vm_id = 9000

# Базовое имя для ВМ кластера (к имени будет добавляться суффикс -master-1, -worker-1 и т.д.)
vm_name_prefix = "k3s-cluster"


# === Ресурсы для ВМ ===

# Количество CPU на ноду
vm_cpu_cores = 2

# Объем оперативной памяти на ноду (в МБ)
vm_memory_mb = 4096

# Размер системного диска (в ГБ)
vm_disk_size_gb = 40

# Тип диска (scsi, virtio, ide)
vm_disk_type = "scsi"


# === Сетевые настройки ===

# Статический IP адрес для первой мастер-ноды (опционально, если не используется DHCP)
# Если пусто, будет использоваться DHCP
master_static_ip = ""

# Маска подсети
subnet_mask = "24"

# Шлюз по умолчанию
gateway = "192.168.1.1"

# DNS серверы (через запятую)
dns_servers = "8.8.8.8,8.8.4.4"

# Диапазон IP адресов для динамического выделения (если не указаны статические)
# Формат: "начальный_ип,конечный_ип"
ip_range_start = "192.168.1.100"
ip_range_end = "192.168.1.200"


# === Настройки кластера ===

# Тип шаблона развертывания: "simple", "middle", "custom"
deployment_template = "simple"

# Для custom шаблона: количество мастер-нод (минимум 1)
custom_master_count = 1

# Для custom шаблона: количество worker-нод
custom_worker_count = 2

# Версия k3s для установки
k3s_version = "v1.28.5+k3s1"

# Метод установки: "ansible" или "k3sup"
installation_method = "ansible"
```

#### Как создать API токен в Proxmox:

1. Откройте веб-интерфейс Proxmox VE
2. Перейдите в **Datacenter** -> **Permissions** -> **API Tokens**
3. Нажмите **Add**
4. Укажите:
   - **User**: root@pam (или другой пользователь с правами администратора)
   - **Token ID**: любое имя, например, `terraform`
   - **Privilege Separation**: снимите галочку (для простоты)
   - **Expiration**: опционально установите срок действия
5. Нажмите **Add**
6. **Скопируйте секрет токена** - он показывается только один раз!
7. Вставьте секрет в `proxmox_api_token_secret`

### 1.3. Настройка Yandex Cloud (yandex.tfvars)

Если планируете использовать Yandex Cloud, заполните `terraform/yandex.tfvars`:

```hcl
# === Авторизация в Yandex Cloud ===

# ID облака (можно получить через: yc config list)
yc_cloud_id = "b1gxxxxxxxxxxxxxxxxx"

# ID каталога (folder_id)
yc_folder_id = "b1gxxxxxxxxxxxxxxxxx"

# Сервисный аккаунт (ID или имя)
yc_service_account_id = "ajexxxxxxxxxxxxxxxxxx"

# Или использовать авторизованный профиль (предварительно выполнить: yc init)
use_authorized_profile = true


# === Настройки сети ===

# ID существующей VPC сети или оставьте пустым для создания новой
vpc_network_id = ""

# ID подсети или оставьте пустым для создания новой
subnet_id = ""

# CIDR блок для новой подсети (если создается новая)
subnet_cidr = "10.0.1.0/24"

# Зона доступности
availability_zone = "ru-central1-a"


# === Ресурсы для ВМ ===

# Тип инстанса (например, standard-2, standard-4 и т.д.)
instance_type = "standard-2"

# Образ ОС (Ubuntu 22.04 LTS)
os_image_family = "ubuntu-22-04-lts"

# Размер системного диска (в ГБ)
disk_size_gb = 40

# Тип диска (network-hdd, network-ssd, network-ssd-nonreplicated)
disk_type = "network-hdd"


# === Настройки кластера ===

deployment_template = "simple"
custom_master_count = 1
custom_worker_count = 2
k3s_version = "v1.28.5+k3s1"
installation_method = "ansible"
```

### 1.4. Шаблоны конфигурации кластера

#### Simple шаблон (templates/simple.tfvars)
```hcl
# Простой кластер: 1 мастер + автоматическое добавление рабочих нод
master_count = 1
worker_count = 2
enable_ha = false
load_balancer_enabled = false
```

#### Middle шаблон (templates/middle.tfvars)
```hcl
# HA кластер: 3 мастера + рабочие ноды
master_count = 3
worker_count = 3
enable_ha = true
load_balancer_enabled = true
# IP для load balancer (опционально)
load_balancer_ip = "192.168.1.50"
```

#### Custom шаблон (templates/custom.tfvars)
```hcl
# Пользовательская конфигурация
master_count = 2
worker_count = 5
enable_ha = true
load_balancer_enabled = false
custom_options = {
  extra_server_args = "--flannel-backend=wireguard"
  extra_agent_args = ""
}
```

---

## 2. Создание шаблона ВМ в Proxmox VE

Для работы установщика необходим шаблон виртуальной машины с предустановленной ОС и cloud-init.

### 2.1. Требования к шаблону

- **ОС**: Ubuntu 22.04 LTS (рекомендуется) или Ubuntu 20.04 LTS
- **Cloud-init**: должен быть установлен и настроен
- **SSH**: сервер SSH должен быть установлен и разрешать вход по ключу
- **Python3**: необходим для работы Ansible
- **QEMU Guest Agent**: рекомендуется для лучшей интеграции с Proxmox

### 2.2. Пошаговая инструкция создания шаблона

#### Шаг 1: Загрузка образа ISO

1. Скачайте образ Ubuntu 22.04 LTS:
   ```bash
   wget https://releases.ubuntu.com/jammy/ubuntu-22.04.3-live-server-amd64.iso -P /var/lib/vz/template/iso/
   ```

2. Или через веб-интерфейс Proxmox:
   - Выберите узел -> **local** -> **ISO Images**
   - Нажмите **Download from URL**
   - Введите URL образа Ubuntu

#### Шаг 2: Создание виртуальной машины

1. В веб-интерфейсе Proxmox нажмите **Create VM**
2. Заполните параметры:
   - **General**:
     - VM ID: `9000` (временный, потом станет шаблоном)
     - Name: `ubuntu-cloud-init-template`
   
   - **OS**:
     - Use CD/DVD disk image file: выберите скачанный ISO Ubuntu
     - Type: Linux 5.x - 2.6 Kernel
   
   - **System**:
     - QEMU Agent: включите галочку
   
   - **Disks**:
     - Storage: local-lvm (или ваше хранилище)
     - Disk size: 10 GB (минимум)
     - Discard: включите для SSD
   
   - **CPU**:
     - Cores: 2
     - Type: host (или x86-64-v2-AES)
   
   - **Memory**:
     - Memory: 2048 MB
   
   - **Network**:
     - Bridge: vmbr0
     - Model: VirtIO (paravirtualized)
   
   - **Confirm**: нажмите **Finish**

#### Шаг 3: Установка Ubuntu

1. Запустите ВМ и откройте консоль
2. Пройдите установку Ubuntu Server:
   - Язык: English (рекомендуется для серверов)
   - Раскладка клавиатуры: по выбору
   - Сеть: используйте DHCP (настроим позже через cloud-init)
   - Proxy: оставьте пустым
   - Mirror: оставьте по умолчанию
   - **Storage configuration**: Use an entire disk
   - Profile setup:
     - Your name: `template`
     - Server name: `template`
     - Username: `ubuntu`
     - Password: задайте временный пароль
   - SSH Setup: **Установите флажок [x] Install OpenSSH server**
   - Featured Server Snaps: можно пропустить
3. Дождитесь завершения установки
4. Когда установка завершится, выберите **Reboot Now**

#### Шаг 4: Установка необходимых пакетов

После перезагрузки войдите в ВМ под пользователем `ubuntu`:

```bash
# Обновите пакеты
sudo apt update && sudo apt upgrade -y

# Установите cloud-init (если еще не установлен)
sudo apt install -y cloud-init qemu-guest-agent

# Установите Python 3 (необходим для Ansible)
sudo apt install -y python3 python3-pip

# Установите дополнительные утилиты
sudo apt install -y curl wget vim net-tools open-vm-tools

# Включите QEMU Guest Agent
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

# Очистите кеш
sudo apt clean
sudo rm -rf /var/cache/apt/archives/*.deb
```

#### Шаг 5: Настройка cloud-init

Cloud-init уже должен быть установлен, но убедитесь, что он корректно настроен:

```bash
# Проверьте статус cloud-init
cloud-init status

# Если нужно, перенастройте
sudo cloud-init clean
sudo cloud-init init
```

#### Шаг 6: Подготовка к клонированию

Перед превращением ВМ в шаблон необходимо очистить систему:

```bash
# Очистите историю команд
history -c
cat /dev/null > ~/.bash_history

# Удалите временные файлы
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Очистите логи
sudo truncate -s 0 /var/log/*.log

# Удалите машиночитаемые идентификаторы
sudo rm -f /etc/machine-id
sudo systemd-machine-id-setup --setup

# Очистите ARP кеш
sudo ip neigh flush all

# Выключите ВМ
sudo shutdown now
```

#### Шаг 7: Превращение ВМ в шаблон

1. В веб-интерфейсе Proxmox выберите вашу ВМ (`9000`)
2. Убедитесь, что ВМ выключена
3. Нажмите правой кнопкой мыши -> **Convert to template**
4. Подтвердите действие

Теперь ВМ стала шаблоном и имеет значок шаблона в списке.

#### Шаг 8: Обновление ID шаблона (опционально)

Если вы хотите использовать другой ID для шаблона:

1. Клонируйте шаблон с новым ID:
   - Правой кнопкой по шаблону -> **Clone**
   - Mode: Full Clone
   - VM ID: например, `9001`
   - Name: `k3s-template`
   - Нажмите **Clone**

2. После клонирования удалите старый шаблон (если не нужен)

3. Обновите `template_vm_id` в `proxmox.tfvars` на новый ID

### 2.3. Альтернативный способ: загрузка готового cloud-image

Можно использовать готовый cloud-image Ubuntu:

```bash
# Скачайте cloud-image
cd /var/lib/vz/template/cache
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Создайте ВМ через командную строку
qm create 9000 --memory 2048 --core 2 --name ubuntu-cloud-template
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:0,import-from=/var/lib/vz/template/cache/jammy-server-cloudimg-amd64.img,discard=on
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --net0 virtio,bridge=vmbr0

# Включите QEMU Agent
qm set 9000 --agent enabled=1

# Превратите в шаблон
qm template 9000
```

---

## 3. Запуск установки кластера

### 3.1. Предварительные требования

Перед запуском убедитесь, что:
- ✅ Заполнены все необходимые переменные в `.tfvars` файлах
- ✅ Создан шаблон ВМ в Proxmox
- ✅ Установлен Terraform (версия 1.0+)
- ✅ Установлен Ansible (версия 2.9+)
- ✅ Установлен k3sup (если выбран метод установки "k3sup")
- ✅ Есть доступ к API Proxmox или авторизация в Yandex Cloud

### 3.2. Установка зависимостей

```bash
# Установка Terraform (для Ubuntu/Debian)
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Установка Ansible
sudo apt update
sudo apt install -y ansible

# Установка k3sup (опционально, если будете использовать)
curl -sLS https://get.k3sup.dev | sh
sudo mv k3sup /usr/local/bin/
```

### 3.3. Инициализация Terraform

```bash
# Перейдите в директорию terraform
cd terraform

# Инициализируйте Terraform
terraform init

# Проверьте конфигурацию
terraform validate

# Просмотрите план выполнения (для Proxmox)
terraform plan -var-file="proxmox.tfvars" -var-file="templates/simple.tfvars"

# Или для Yandex Cloud
terraform plan -var-file="yandex.tfvars" -var-file="templates/simple.tfvars"
```

### 3.4. Развертывание инфраструктуры

```bash
# Примените конфигурацию (для Proxmox)
terraform apply -var-file="proxmox.tfvars" -var-file="templates/simple.tfvars"

# Подтвердите выполнение, введя "yes"

# После завершения вы увидите вывод с информацией о созданных ВМ
# Сохраните этот вывод - там есть IP адреса нод
```

### 3.5. Запуск Ansible/k3sup

После успешного создания ВМ скрипт `install.sh` автоматически запустит настройку:

```bash
# Вернитесь в корень проекта
cd ..

# Запустите скрипт установки
./install.sh
```

Или выполните шаги вручную:

#### Для метода Ansible:

```bash
# Перейдите в директорию ansible
cd ansible

# Создайте инвентарь (если не создан автоматически)
# Скрипт должен был создать его на основе вывода terraform

# Запустите плейбук подготовки
ansible-playbook -i inventory.ini playbooks/prepare.yml

# Запустите плейбук установки k3s
ansible-playbook -i inventory.ini playbooks/install-k3s.yml

# Запустите пост-настройку
ansible-playbook -i inventory.ini playbooks/post-configure.yml
```

#### Для метода k3sup:

```bash
# Перейдите в директорию scripts
cd scripts

# Запустите скрипт установки через k3sup
./k3sup-install.sh
```

---

## 4. Проверка результата

### 4.1. Проверка статуса нод

```bash
# Подключитесь к мастер-ноде
ssh ubuntu@<MASTER_IP>

# Проверьте статус нод кластера
kubectl get nodes

# Ожидаемый вывод:
# NAME           STATUS   ROLES                  AGE   VERSION
# master-1       Ready    control-plane,master   5m    v1.28.5+k3s1
# worker-1       Ready    <none>                 4m    v1.28.5+k3s1
# worker-2       Ready    <none>                 4m    v1.28.5+k3s1
```

### 4.2. Проверка подов

```bash
# Проверьте системные поды
kubectl get pods -A

# Все поды должны быть в статусе Running
```

### 4.3. Проверка сервисов

```bash
# Проверьте сервисы
kubectl get svc -A

# Проверьте Traefix (встроенный ingress контроллер)
kubectl get pods -n kube-system -l app=traefik
```

### 4.4. Доступ к кластеру с локальной машины

```bash
# Скопируйте kubeconfig с мастер-ноды
scp ubuntu@<MASTER_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Замените сервер в конфиге на реальный IP
sed -i 's/127.0.0.1/<MASTER_IP>/g' ~/.kube/config

# Проверьте доступ
kubectl get nodes
```

---

## 5. Устранение неполадок

### 5.1. Проблемы с Terraform

**Ошибка: "connection to proxmox failed"**
- Проверьте правильность `proxmox_api_url`
- Убедитесь, что токен действителен
- Проверьте сетевую доступность узла Proxmox
- Для самоподписанных сертификатов установите `proxmox_tls_insecure = true`

**Ошибка: "template VM not found"**
- Убедитесь, что `template_vm_id` соответствует реальному ID шаблона
- Проверьте, что шаблон находится в том же узле (`proxmox_node`)

**Ошибка: "no available IP addresses"**
- Расширьте диапазон в `ip_range_start` и `ip_range_end`
- Или используйте статические IP адреса

### 5.2. Проблемы с Ansible

**Ошибка: "Failed to connect to the host via ssh"**
- Проверьте, что у вас есть SSH ключи для доступа к ВМ
- Убедитесь, что cloud-init корректно настроил SSH
- Проверьте логи cloud-init на ВМ: `/var/log/cloud-init-output.log`

**Ошибка: "python3 not found"**
- Убедитесь, что Python 3 установлен в шаблоне ВМ
- Добавьте установку python3 в процесс создания шаблона

### 5.3. Проблемы с k3s

**Ноды не подключаются к кластеру**
- Проверьте сетевую связность между нодами
- Убедитесь, что порты 6443, 2379-2380 открыты
- Проверьте логи k3s: `journalctl -u k3s -f`

**Поды в статусе Pending**
- Проверьте доступные ресурсы (CPU, память)
- Проверьте события: `kubectl get events --sort-by='.lastTimestamp'`

### 5.4. Полезные команды для диагностики

```bash
# Просмотр логов cloud-init
cat /var/log/cloud-init-output.log

# Проверка статуса k3s
systemctl status k3s

# Логи k3s
journalctl -u k3s -f

# Проверка сетевых подключений
netstat -tlnp | grep -E '6443|2379|2380'

# Проверка сертификатов
kubectl get certificates -A
```

---

## Дополнительные ресурсы

- [Документация k3s](https://docs.k3s.io/)
- [Документация Terraform Proxmox Provider](https://registry.terraform.io/providers/telmate/proxmox/latest/docs)
- [Документация Ansible](https://docs.ansible.com/)
- [k3sup GitHub](https://github.com/alexellis/k3sup)
- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)

---

## Следующие шаги

После успешной установки базового кластера вы можете:

1. Установить Helm и добавить репозитории
2. Развернуть мониторинг (Prometheus + Grafana)
3. Настроить ingress контроллер
4. Развернуть приложения в кластере
5. Настроить резервное копирование (Velero)
6. Настроить автоматическое масштабирование

Удачи в развертывании! 🚀
