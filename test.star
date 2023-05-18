nginx_package = import_module("github.com/adschwartz/nginx-package/main.star")

NOVU_VERSION = "0.14.0"
WAIT_DISABLE = None

NOVU_WEB_IMAGE = "ghcr.io/novuhq/novu/web:%s" % NOVU_VERSION
NOVU_WEB_SERVICE_NAME = "novu_web"
NOVO_WEB_PORT_NAME = NOVU_WEB_SERVICE_NAME
NOVU_WEB_PROTOCOL_NAME = "http"
NOVU_WEB_PORT = 4200


def run(plan, args):
    NOVU_DOCKER_HOSTED = "true"
    NOVU_NODE_ENV = "local"

    # REACT_APP_WS_URL = "ws://novu_ws:3002"
    # REACT_APP_API_URL= "http://novu_api:3000"
    # REACT_APP_WIDGET_EMBED_PATH = "http://novu_widget:4500/embed.umd.min.js"

    NGINX_PORT = 80
    REACT_APP_API_URL = "http://localhost:%d/api" % NGINX_PORT
    REACT_APP_WS_URL = "http://localhost:%d/ws" % NGINX_PORT
    REACT_APP_WIDGET_EMBED_PATH = "http://localhost:%d/widget_embed/embed.umd.min.js" % NGINX_PORT

    #Add Novu Web Service
    novu_web_service = plan.add_service(
        name=NOVU_WEB_SERVICE_NAME,
        config=ServiceConfig(
            image=NOVU_WEB_IMAGE,
            ports={
                NOVO_WEB_PORT_NAME: PortSpec(
                    number=NOVU_WEB_PORT,
                    application_protocol=NOVU_WEB_PROTOCOL_NAME,
                    wait=WAIT_DISABLE,
                ),
            },
            env_vars={
                "REACT_APP_API_URL": REACT_APP_API_URL,
                "REACT_APP_ENVIRONMENT": "local",  #NOVU_NODE_ENV,
                "REACT_APP_WIDGET_EMBED_PATH": REACT_APP_WIDGET_EMBED_PATH,
                "REACT_APP_DOCKER_HOSTED_ENV": NOVU_DOCKER_HOSTED,
                "REACT_APP_WS_URL": REACT_APP_WS_URL,
            },
        ),
    )

    # file = plan.upload_files(
    #     src = "github.com/kurtosis-tech/novu-package/nginx.conf@anders/novu",
    #     name = "test"
    # )
    args = {
        "config_files_artifact": "test"
    }
    nginx_package.run(plan, args)

    return
