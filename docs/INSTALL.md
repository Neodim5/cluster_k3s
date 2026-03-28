# Установка зависимостей и настройка проекта

Этот документ описывает процесс установки всех необходимых зависимостей и начальной настройки проекта для развертывания кластера k3s.

## Содержание

1. [Автоматическая установка](#1-автоматическая-установка)
2. [Ручная установка](#2-ручная-установка)
3. [Настройка конфигурации](#3-настройка-конфигурации)
4. [Создание шаблона ВМ](#4-создание-шаблона-вм)
5. [Проверка установки](#5-проверка-установки)

---

## 1. Автоматическая установка

### 1.1. Использование скрипта setup.sh

Скрипт `setup.sh` автоматически проверит зависимости, скопирует конфигурационные файлы и инициализирует Terraform.

```bash
# Перейдите в корень проекта
cd /workspace

# Запустите скрипт настройки (все шаги)
./scripts/setup.sh

# Или только проверка зависимостей
./scripts/setup.sh -a check

# Только копирование конфигов
./scripts/setup.sh -a setup

# С выбором параметров
./scripts/setup.sh -e dev -c proxmox -t simple
```

### 1.2. Параметры скрипта

| Параметр | Описание | По умолчанию |
|----------|----------|--------------|
| `-e, --environment` | Имя окружения (dev, prod) | dev |
| `-c, --cloud` | Облачный провайдер (proxmox, yandex) | proxmox |
| `-t, --template` | Шаблон кластера (simple, middle, custom) | simple |
| `-a, --action` | Действие (check, setup, all) | all |

### 1.3. Примеры использования

```bash
# Полная настройка для Proxmox с простым кластером
./scripts/setup.sh -e dev -c proxmox -t simple

# Настройка для Yandex Cloud с HA кластером
./scripts/setup.sh -e prod -c yandex -t middle

# Только проверка зависимостей
./scripts/setup.sh -a check

# Кастомный кластер в dev окружении
./scripts/setup.sh -e dev -c proxmox -t custom
```

---

## 2. Ручная установка

### 2.1. Установка Terraform

#### Ubuntu/Debian

```bash
# Добавьте репозиторий HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

# Установите Terraform
sudo apt update && sudo apt install terraform

# Проверьте версию
terraform version
```

#### macOS

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Проверьте версию
terraform version
```

#### CentOS/RHEL

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform

# Проверьте версию
terraform version
```

### 2.2. Установка Ansible

#### Ubuntu/Debian

```bash
sudo apt update
sudo apt install -y ansible

# Проверьте версию
ansible --version
```

#### macOS

```bash
brew install ansible

# Проверьте версию
ansible --version
```

#### pip (универсальный способ)

```bash
pip3 install ansible

# Проверьте версию
ansible --version
```

### 2.3. Установка kubectl

#### Ubuntu/Debian

```bash
# Скачайте последнюю версию
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Сделайте исполняемым и переместите
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Проверьте версию
kubectl version --client
```

#### macOS

```bash
brew install kubectl

# Проверьте версию
kubectl version --client
```

### 2.4. Установка k3sup (опционально)

k3sup - утилита для быстрой установки k3s через SSH.

```bash
# Скачать и установить
curl -sLS https://get.k3sup.dev | sh
sudo mv k3sup /usr/local/bin/

# Проверьте версию
k3sup version
```

### 2.5. Генерация SSH ключа

```bash
# Создайте новый SSH ключ (рекомендуется ed25519)
ssh-keygen -t ed25519 -f ~/.ssh/k3s_cluster -N ""

# Или используйте существующий ключ
# ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Добавьте публичный ключ в агент SSH
ssh-add ~/.ssh/k3s_cluster

# Проверьте наличие ключа
ls -la ~/.ssh/*.pub
```

### 2.6. Дополнительные утилиты

```bash
# curl и wget (часто уже установлены)
sudo apt install -y curl wget

# git для работы с репозиторием
sudo apt install -y git

# jq для работы с JSON
sudo apt install -y jq
```

---

## 3. Настройка конфигурации

### 3.1. Копирование примера конфигурации

```bash
# Перейдите в директорию проекта
cd /workspace

# Скопируйте пример конфигурации Proxmox
cp terraform/environments/dev/proxmox.tfvars.example \
   terraform/environments/dev/proxmox.tfvars

# Или для Yandex Cloud
cp terraform/yandex.tfvars \
   terraform/environments/dev/yandex.tfvars
```

### 3.2. Редактирование конфигурации Proxmox

Откройте файл `terraform/environments/dev/proxmox.tfvars` и заполните:

```hcl
# === Обязательные параметры ===

# Адрес вашего сервера Proxmox
proxmox_api_url = "https://192.168.1.100:8006/api2/json"

# Токен API (создается в Proxmox)
proxmox_api_token_secret = "YOUR_TOKEN_SECRET_HERE"

# Имя узла Proxmox
proxmox_node = "pve"

# Сетевые настройки вашей сети
gateway = "192.168.1.1"
dns_servers = "8.8.8.8,8.8.4.4"
ip_range_start = "192.168.1.100"
ip_range_end = "192.168.1.200"

# ID шаблона ВМ (будет указан после создания шаблона)
template_vm_id = 9000
```

### 3.3. Создание API токена в Proxmox

1. Откройте веб-интерфейс Proxmox VE
2. Перейдите в **Datacenter** → **Permissions** → **API Tokens**
3. Нажмите **Add**
4. Заполните:
   - **User**: `root@pam` (или ваш пользователь)
   - **Token ID**: `terraform` (любое имя)
   - **Privilege Separation**: снимите галочку
5. Нажмите **Add**
6. **Скопируйте секрет токена** (показывается один раз!)
7. Вставьте в файл конфигурации

### 3.4. Конфигурация для Yandex Cloud

Для Yandex Cloud отредактируйте `terraform/environments/dev/yandex.tfvars`:

```hcl
# ID облака (yc config list)
yc_cloud_id = "b1gxxxxxxxxxxxxxxxxx"

# ID каталога
yc_folder_id = "b1gxxxxxxxxxxxxxxxxx"

# Сервисный аккаунт или профиль
use_authorized_profile = true
# или
yc_service_account_id = "ajexxxxxxxxxxxxxxxxxx"
```

---

## 4. Создание шаблона ВМ

### 4.1. Быстрый способ (готовый cloud-image)

```bash
# Скачайте cloud-image Ubuntu 22.04
cd /var/lib/vz/template/cache
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Создайте ВМ через CLI Proxmox
qm create 9000 --memory 2048 --core 2 --name ubuntu-k3s-template
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:0,import-from=/var/lib/vz/template/cache/jammy-server-cloudimg-amd64.img,discard=on
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --net0 virtio,bridge=vmbr0
qm set 9000 --agent enabled=1

# Превратите в шаблон
qm template 9000

# Обновите template_vm_id в конфиге
# template_vm_id = 9000
```

### 4.2. Ручной способ (из ISO)

1. Скачайте ISO Ubuntu Server 22.04
2. Создайте ВМ в интерфейсе Proxmox
3. Установите Ubuntu
4. Установите пакеты:
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y cloud-init qemu-guest-agent python3
   ```
5. Очистите систему и выключите
6. Конвертируйте в шаблон

Подробная инструкция в `docs/setup_guide.md`.

---

## 5. Проверка установки

### 5.1. Проверка зависимостей

```bash
# Используйте встроенный скрипт проверки
./scripts/check_dependencies.sh

# Или вручную проверьте версии
terraform version
ansible --version
kubectl version --client
k3sup version  # опционально
```

### 5.2. Проверка структуры проекта

```bash
# Проверьте наличие всех необходимых файлов
tree -L 3 /workspace/

# Должны присутствовать:
# ├── terraform/
# │   ├── environments/dev/proxmox.tfvars
# │   ├── templates/simple.tfvars
# │   ├── templates/middle.tfvars
# │   └── templates/custom.tfvars
# ├── ansible/
# ├── scripts/
# │   ├── setup.sh
# │   ├── check_dependencies.sh
# │   └── install.sh
# └── docs/
```

### 5.3. Инициализация Terraform

```bash
cd /workspace/terraform

# Инициализируйте провайдеры
terraform init

# Проверьте конфигурацию
terraform validate

# Просмотрите план (без применения)
terraform plan \
  -var-file="environments/dev/proxmox.tfvars" \
  -var-file="templates/simple.tfvars"
```

### 5.4. Тестовое развертывание

После успешной проверки можно запустить развертывание:

```bash
# Вернитесь в корень проекта
cd /workspace

# Запустите установку
./scripts/install.sh -e dev -t simple -c proxmox

# Или по шагам:
./scripts/01_terraform.sh -e dev -c proxmox -t simple
./scripts/02_ansible_prepare.sh -e dev -c proxmox
./scripts/03_ansible_k3s.sh -e dev -t simple
./scripts/04_configure.sh -e dev
```

---

## Устранение проблем

### Terraform не находит провайдер

```bash
# Очистите кеш и переинициализируйте
cd /workspace/terraform
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Ошибка подключения к Proxmox

- Проверьте URL API (`proxmox_api_url`)
- Убедитесь, что токен действителен
- Для самоподписанных сертификатов: `proxmox_tls_insecure = true`
- Проверьте сетевую доступность: `ping <IP_PROXMOX>`

### Ansible не подключается по SSH

- Проверьте путь к SSH ключу в конфиге
- Убедитесь, что ключ добавлен в агент: `ssh-add -l`
- Проверьте права на файл ключа: `chmod 600 ~/.ssh/k3s_cluster`

### Нет шаблона ВМ

- Создайте шаблон согласно инструкции выше
- Укажите правильный `template_vm_id` в конфиге
- Убедитесь, что шаблон находится на том же узле (`proxmox_node`)

---

## Следующие шаги

После успешной настройки:

1. ✅ Зависимости установлены
2. ✅ Конфигурация заполнена
3. ✅ Шаблон ВМ создан
4. ✅ Terraform инициализирован

**Запускайте установку кластера:**

```bash
./scripts/install.sh -e dev -t simple -c proxmox
```

Или следуйте подробному руководству в `docs/setup_guide.md`.
