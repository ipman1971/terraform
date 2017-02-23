# Laboratorio con Terraform

Este repositorio tiene como fin el aprender los conocimientos básicos para poder generar infraestrutura a partir de código(IAC) mediante el uso de [Terraform](https://www.terraform.io).

Nuestras prácticas se realizan sobre [OpenStack](https://www.openstack.org/) como proveedor de la infraestructura.

## Requisitos hardware
En nuestro laboratorio hemos utilizado una maquina dedicada del proveedor [Hetzner](https://www.hetzner.de/) con las siguientes caracteristicas:

| Procesador | Almacenamiento | Memoria |
| :---       | :---           | :---    |
|Intel Core i7-950 | 2x HDD 2,0 TB SATA Enterprise | 6x RAM DDR3 8192 MB |

## Requisitos software
Sobre la máquina se ha instalado Linux Ubuntu Server 16.04, DevStack versión Newton y Terraform 0.8.7

## Instalación de DevStack
Para poder disponer de OpenStack en sobre una unica máquina se ha procedido ha instalar [DevStack](https://docs.openstack.org/developer/devstack/)

### Procedimiento de instalación

1. Crear un usuario **stack** especifico para DevStack
```bash
adduser stack --shell /bin/bash --home /home/stack
```
2. Dar capacidadd de ***sudo*** al usuario **stack**
```bash
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
```
3. Actualizar paquetes del sistema
```bash
apt-get update
```
4. Instalar ***git***
```bash
apt-get install git
```
5. Cambiar al usuario **stack**
```bash
su stack
```
6. Cambiar al directorio HOME
```bash
cd $HOME
```
7. Clonar el repositorio de DevStack
```bash
git clone https://git.openstack.org/openstack-dev/devstack
```
8. Posicionarnos en el directorio ***devstack***
```bash
cd devstack
```
9. Cambiar a la rama estable para la version **Newton** de DevStack que deseamos instalar según las versiones posibles indicadas en el repo git. [Versiones estables](https://github.com/openstack-dev/devstack/branches)
```bash
git checkout stable/newton
```
10. Creamos la configuración minima para DevStack creando el fichero **local.conf** con el siguiente contenido, donde ***secret*** debe ser la password del usuario ***admin*** que nos da acceso a nuestro Openstack.
```bash
[[local|localrc]]
ADMIN_PASSWORD=secret
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
```
11. Lanzar la instalación de devstack y esperar a que finalize
```bash
./stack.sh
```
12. Acceder a la consola de administración en [http://tu-ip-server/dashboard](http://tu-ip-server/dashboard)

### Requisitos en DevStack
Definimos aqui todos los requisitos necesarios para poder realizar los laboratorios

1. Creación de un proyecto dedicado con las ***quotas*** necesarias.
2. Usuario para el proyecto con rol de ***ResellerAdmin***.
3. Imagen [Debian 8.7.0](http://cdimage.debian.org/cdimage/openstack/current/debian-8.7.1-20170215-openstack-amd64.qcow2) disponible para el proyecto

## Laboratorios disponibles

| ID    | Descripción |
| :---: | :---        |
| [example-1](./example-1) | Creación de un web-server con ***ip privada*** e ***ip flotante*** |
| [example-2](./example-2) | Creación de un cluster de webservers con ***ip privada*** cuyo número depende del párametro ***cluster_size*** |
| [example-3](./example-3) | Creación de un cluster de webservers con ***ip privada*** cuyo número depende del párametro ***cluster_size*** asociadoa a una zona de disponibilidad y generando un fichero yml con información de las instancias creadas |
