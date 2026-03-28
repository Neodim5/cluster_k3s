# Краткое руководство по настройке

Этот документ содержит краткую инструкцию для быстрого начала работы с проектом.

## Быстрый старт (3 шага)

### Шаг 1: Проверка и настройка зависимостей

```bash
cd /workspace

# Автоматическая проверка зависимостей
./scripts/check_dependencies.sh

# Если все ОК, запустите полную настройку
./scripts/setup.sh -e dev -c proxmox -t simple
```

### Шаг 2: Создание шаблона ВМ в Proxmox

**Быстрый способ (5 команд):**

```bash
# На сервере Proxmox выполните:
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

**Важно:** Запомните ID шаблона (9000) и укажите его в конфиге.

### Шаг 3: Редактирование конфигурации

Откройте `terraform/environments/dev/proxmox.tfvars` и заполните:

```hcl
proxmox_api_url = "https://<IP_PROXMOX>:8006/api2/json"
proxmox_api_token_secret = "<ВАШ_ТОКЕН>"
proxmox_node = "pve"
gateway = "192.168.1.1"
template_vm_id = 9000
```

**Как создать токен в Proxmox:**
1. Datacenter → Permissions → API Tokens
2. Add → User: root@pam, Token ID: terraform
3. Скопируйте секрет (показывается один раз!)

### Шаг 4: Запуск установки

```bash
cd /workspace

# Вариант A: Автоматический скрипт
./scripts/install.sh -e dev -t simple -c proxmox

# Вариант B: По шагам
cd terraform
terraform init
terraform plan -var-file="environments/dev/proxmox.tfvars" -var-file="templates/simple.tfvars"
terraform apply -var-file="environments/dev/proxmox.tfvars" -var-file="templates/simple.tfvars"
```

## Проверка результата

```bash
# После установки проверьте кластер
kubectl get nodes
kubectl get pods -A
```

## Документы для подробной информации

| Документ | Описание |
|----------|----------|
| [docs/INSTALL.md](INSTALL.md) | Полная инструкция по установке зависимостей |
| [docs/setup_guide.md](setup_guide.md) | Подробное руководство по настройке |
| [docs/QUICKSTART.md](QUICKSTART.md) | Шпаргалка по командам |
| [README.md](../README.md) | Общая информация о проекте |

## Устранение проблем

### Ошибка подключения к Proxmox
- Проверьте URL API и токен
- Для самоподписанных сертификатов: `proxmox_tls_insecure = true`

### Terraform не находит шаблон
- Убедитесь, что `template_vm_id` соответствует реальному ID
- Проверьте, что шаблон находится на том же узле (`proxmox_node`)

### SSH не подключается
- Проверьте путь к ключу в конфиге
- Убедитесь, что ключ добавлен: `ssh-add -l`

## Следующие шаги после установки

1. Настройте доступ к кластеру: `scp ubuntu@<MASTER_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/config`
2. Установите ingress контроллер
3. Разверните ваши приложения
4. Настройте мониторинг и бэкапы

---

**Готово!** Ваш кластер k3s работает! 🎉
