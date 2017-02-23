# Laboratorio: example-2

## Objetivos
En este laboratorio debemos conseguir los siguientes objetivos:

1. Crear un cluster de máquinas que realice tareas de servidor web.
2. Parámetrizar el numero de máquinas que forman el cluster.
3. Crear tres zonas de disponibilidad asocidas a una región
3. Crear tres instancias por zona de disponibilidad.
3. Todas las máquinas deben pertenecer a una red privada con IPs del tipo 10.0.10.x
4. Todas las máquinas deben poder ser accedidas mediante SSH.
5. Todas las máquinas deben responder al comando ***ping***.
6. El nombre de la máquinas se debe ajustar al patron "ws-zona de disponibilidad-XX".

## Esquema de red deseado
![](./images/example2-esquema-red.png)
![](./images/example2-topologia-red.png)
![](./images/example2-instancias.png)

## Outputs
Se debera mostrar la lista de ips de las máquinas que conforman el cluster y la lista de zonas de disponibilidad
![](./images/example2-outputs.png)
