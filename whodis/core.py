import socket
import collections

from geolite2 import geolite2


class GeoIP(object):
    """Helper class to provide geo information for an IP
    """
    def __init__(self):
        self._geoip = geolite2.reader()

    def get_info(self, addr):
        data = self._geoip.get(addr)

        if data:
            city = self._get_en_name(data.get('city'))
            country = self._get_en_name(data.get('country'))
        else:
            city, country = None, None
        return GeoInfo(city, country)

    def _get_en_name(self, data):
        if not data:
            return None
        names = data.get('names') or {}
        return names.get('en')


class GeoInfo(object):
    def __init__(self, city, country):
        self.city = city
        self.country = country


def check_ports(addr, ports):
    """Checks if ports are reachable on an address.

    Returns a list of PortInfo objects.
    """
    if not isinstance(ports, collections.Sequence):
        raise ValueError("invalid ports list")
    port_map = {}
    for index, value in enumerate(ports):
        try:
            port_info = PortInfo(value)
            port_map[port_info.port] = port_info
        except ValueError as e:
            raise ValueError("bad port at index %s: %s" % (index, str(e)))

    if len(port_map) > 10:
        raise ValueError("max of 10 ports may be checked")

    # slow. would be better to fire them off in batches async and select()
    for port_info in port_map.values():
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            s.settimeout(1)
            s.connect((addr, port_info.port))
            port_info.reachable = True
        except Exception:
            port_info.reachable = False
        finally:
            s.close()

    return [port_map[k] for k in sorted(port_map.keys())]


class PortInfo(object):
    def __init__(self, value):
        if not value:
            raise ValueError(value)
        self.port = int(value)
        if not 1 <= self.port <= 65535:
            raise ValueError(value)

        # we set reachable to None at first, then True/False after we check
        self.reachable = None


def get_hostname(addr):
    """Best effort attempt to get a hostname for an address
    """
    try:
        result = socket.gethostbyaddr(addr)
        if result:
            return result[0]
    except socket.herror:
        pass
    return None
