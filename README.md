# ESXi-for-ARM
VMware: Cómo extraer la información sobre Temperatura de ESXi for ARM, enviarla a InfluxDB, y visualizarlo con Grafana

https://github.com/thebel1/thpimon

Para descargar el plugin desde nuestro ESXi por SSH, tendremos que desactivar primero el firewall para que pueda conectarse por el cliente http de ESXi, además de tener que bajar la seguridad del sistema para que podamos instalar este plugin:

esxcli software acceptance set --level=CommunitySupported
esxcli network firewall ruleset set -e true -r httpClient

Una vez tenemos realizados estos cambios, procederemos a descargar el paquete, directamente desde el GitHub de Tom, echar un vistazo vosotros, ya que puede nuevas versiones:

esxcli software vib install -v /thpimon-0.1.0-1OEM.701.1.0.40650718.aarch64.vib

Esto os tendría que mostrar algo similar a esto, pasados unos segundos o hasta un minuto:

Installation Result
Message: Operation finished successfully.
Reboot Required: false
VIBs Installed: THX_bootbank_thpimon_0.1.0-1OEM.701.1.0.40650718
VIBs Removed:
VIBs Skipped:

Aunque el VIB dice que no hay que reiniciar, realmente es lo recomendado, así que ya sabéis:

reboot

Una vez reiniciamos, comprobamos que tenemos un nuevo dispositivo en /dev/vmgfxXX en mi caso es /dev/vmgfx32.

Nota: Poner esto en una partición de scratch o en algún datastore donde el ESXi pueda acceder para conservarlo aunque reiniciemos.

Ahora descargaremos el ejemplo de monitorizar la RPi que tiene nuestro amigo Tom.Tan sencillo como realizar los siguiente pasos:

mkdir /scratch/downloads
cd /scratch/downloads
wget https://github.com/thebel1/thpimon/archive/main.zip
unzip main.zip

Antes de lanzar el script, nos iremos con vi a editar el siguiente fichero /scratch/downloads/thpimon-main/pyUtil/pimonLib/init.py

Y modificaremos la línea llamada PIMON_DEVICE_PATH con nuestro dispositivo nuevo, tal que así:

################################################################################
import math
import struct
import fcntl
#########################################################################
PIMON_DEVICE_PATH = '/dev/vmgfx32'
#########################################################################
RPIQ_BUFFER_LEN = 32
RPIQ_PROCESS_REQ = 0

Vamos a probar que todo funciona, lanzaremos el siguiente script, que debería de darnos la información necesaria:

./thpimon-main/pyUtil/pimon_util.py
Firmware Revision: 0x5f440c10
Board Model: 0
Board Revision: 0xd03114
Board MAC Address: f7:12:b1:32:a6:dc
Board Serial: 0x000000ab401f61
Temp: 38.0 (deg. C)

¡Ya tenemos la parte más importante! Muchas gracias, de nuevo a Tom Hebel por su gran trabajo.
Descargar Script para recoger información crear el .json

Es la hora de descargar y configurar el script tan simple que he creado, podemos descargarlo desde aquí, directamente al ESXi for ARM:

cd /scratch/downloads/
wget https://raw.githubusercontent.com/jorgedlcruz/esxi_arm-grafana/main/esxi-arm-rpi_grafana.sh

Hay que editar algunos valores, para funcione correctamente, estos valores:

# Configurations
##
thepimonPath="/scratch/downloads/thpimon-main/pyUtil/pimon_util.py"

Haremos ejecutable el Script, como siempre:

chmod +x esxi-arm-rpi_grafana.sh

Y lanzaremos el script para ver que funciona:

./esxi-arm-rpi_grafana.sh
./esxi-arm-rpi_grafana.sh Building the JSON file All good, now you can go to https://esxi-zlon-rpi-001.jorgedelacruz.es/ui/pimonarm.json and use the JSON on your favourite Monitoring system

With this done, now you have a valid .json ANYTHING can take and parse, as long as they have access over HTTPS to the ESXi for ARM. I am using telegraf, so let’s take a look.
Crear cron para que se ejecute el Script cada minuto

Muchos de los cambios que hemos realizado se perderán al reiniciar, incluido el cron, pero bueno os lo dejo para que lo tengáis a mano, nos iremos al fichero /var/spool/cron/crontabs/root y lo editamos:

vi /var/spool/cron/crontabs/root

*/1 * * * * /scratch/downloads/esxi-arm-rpi_grafana.sh

Vale, pues ya está, cada minuto enviaremos la información a InfluxDB.
