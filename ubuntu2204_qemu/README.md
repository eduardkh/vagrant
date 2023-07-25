# mytestbox
## DRIVER = Hyper-V
## IMAGE = "generic/ubuntu2204"
## VERSION = "4.1.8"
## MEM = 4GB

> use qemu

```bash
brew install qemu
vagrant plugin install vagrant-qemu
vagrant up --provider qemu
```
