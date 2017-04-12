from flask import Flask, request, json, make_response, abort

import core


geoIP = core.GeoIP()
app = Flask(__name__)


@app.route('/')
def addr_info():
    remote_addr = get_remote_addr()

    if wants_json():
        geo_info = geoIP.get_info(remote_addr)
        return json.jsonify(
            ip=remote_addr, hostname=core.get_hostname(remote_addr),
            country=geo_info.country, city=geo_info.city)
    else:
        # if plain text was requested, return just the addr
        return plain_text(remote_addr + "\n")


@app.route('/ports', methods=['POST'])
def check_ports():
    """Checks a JSON list of ports to determine if they are reachable
    """
    remote_addr = get_remote_addr()

    if not request.is_json:
        abort(400)

    request_json = request.get_json()

    try:
        ports = core.check_ports(remote_addr, request_json)
    except ValueError as e:
        abort(400, str(e))

    ports_response = [dict(port=p.port, reachable=p.reachable) for p in ports]
    return json.jsonify(ip=remote_addr, ports=ports_response)


##############################################################################
# FLASK HELPER METHODS
##############################################################################

def wants_json():
    """Returns a boolean if JSON output was requested (via Accept header)
    """
    return request.accept_mimetypes.accept_json


def get_remote_addr():
    """Safely gets the remote addr from a request
    """
    forwarded = request.headers.get('X-Forwarded-For', request.remote_addr)
    # if there are multiple values in the header, use the last one.
    return forwarded.split(",")[-1]


def plain_text(text):
    """Creates a text/plain Response object
    """
    response = make_response(text)
    response.content_type = "text/plain"
    return response
