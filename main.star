redis_module = import_module("github.com/kurtosis-tech/redis-package/main.star")
mongodb_module = import_module("github.com/kurtosis-tech/mongodb-package/main.star")

# Redis
NOVU_REDIS_PORT = 6379
NOVU_REDIS_CACHE_SERVICE_PORT = 6379
NOVU_REDIS_DB_INDEX = 2

# MongoDB
MONGODB_IMAGE = "mongo:latest"
MONGODB_NAME_ARG = "name"
MONGODB_NAME="mongodb"
NOVU_MONGODB_DB = "novu-db"

# NOVU shared settings
NOVU_VERSION = "0.14.0"
NOVU_DOCKER_HOSTED = "true"
NOVU_NODE_ENV = "local"
NOVU_WIDGET_CONTEXT_PATH = ""

# NOVU API
NOVU_API_IMAGE = "ghcr.io/novuhq/novu/api:0.14.0"
NOVU_API_SERVICE_NAME = "novu_api"
NOVO_API_PORT_NAME = "novu_api_port"
NOVU_API_PROTOCOL_NAME = "http"
NOVU_API_DEFAULT_PORT = 3000

# WORKER
NOVU_WORKER_IMAGE = "ghcr.io/novuhq/novu/worker:%s" % NOVU_VERSION
NOVU_WORKER_SERVICE_NAME = "novu_worker"

# NOVU WS
NOVU_WS_IMAGE = "ghcr.io/novuhq/novu/ws:%s" % NOVU_VERSION
NOVU_WS_SERVICE_NAME = "novu_ws"
NOVU_WS_PROTOCOL_NAME = "ws"
NOVO_WS_PORT_NAME = NOVU_WS_SERVICE_NAME
NOVU_WS_PORT = 3002

# NOVU Widget
NOVU_WIDGET_IMAGE = "ghcr.io/novuhq/novu/widget:%s" % NOVU_VERSION
NOVU_WIDGET_SERVICE_NAME = "novu_widget"
NOVO_WIDGET_PORT_NAME = NOVU_WIDGET_SERVICE_NAME
NOVU_WIDGET_PROTOCOL_NAME = "http"
NOVU_WIDGET_PORT = 4500

# NOVU Embed
NOVU_EMBED_IMAGE = "ghcr.io/novuhq/novu/embed:%s" % NOVU_VERSION
NOVU_EMBED_SERVICE_NAME = "novu_embed"
NOVO_EMBED_PORT_NAME = NOVU_EMBED_SERVICE_NAME
NOVU_EMBED_PROTOCOL_NAME = "http"
NOVU_EMBED_PORT = 4701

# NOVU Web
NOVU_WEB_IMAGE = "ghcr.io/novuhq/novu/web:%s" % NOVU_VERSION
NOVU_WEB_SERVICE_NAME = "novu_web"
NOVO_WEB_PORT_NAME = NOVU_WEB_SERVICE_NAME
NOVU_WEB_PROTOCOL_NAME = "http"
NOVU_WEB_PORT = 4200

# # NOVU Notification demo
# NOVU_WEB_IMAGE = "ghcr.io/novuhq/novu/web:%s" % NOVU_VERSION
# NOVU_WEB_SERVICE_NAME = "novu_web"
# NOVO_WEB_PORT_NAME = NOVU_WEB_SERVICE_NAME
# NOVU_WEB_PROTOCOL_NAME = "http"
# NOVU_WEB_PORT = 4200


WAIT_DISABLE = None

# NOVU API
NOVU_ENV_VAR_DEFAULT_NODE_ENV = ""
NOVU_ENV_VAR_DEFAULT_API_ROOT_URL = ""
NOVU_ENV_VAR_DEFAULT_DISABLE_USER_REGISTRATION = ""
NOVU_ENV_VAR_DEFAULT_API_PORT = ""
NOVU_ENV_VAR_DEFAULT_FRONT_BASE_URL = ""
NOVU_ENV_VAR_DEFAULT_MONGO_URL = ""
NOVU_ENV_VAR_DEFAULT_REDIS_CACHE_SERVICE_HOST = ""
NOVU_ENV_VAR_DEFAULT_REDIS_CACHE_SERVICE_PORT = ""
NOVU_ENV_VAR_DEFAULT_S3_LOCAL_STACK = ""
NOVU_ENV_VAR_DEFAULT_S3_BUCKET_NAME = ""
NOVU_ENV_VAR_DEFAULT_S3_REGION = ""
NOVU_ENV_VAR_DEFAULT_AWS_ACCESS_KEY_ID = ""
NOVU_ENV_VAR_DEFAULT_AWS_SECRET_ACCESS_KEY = ""
NOVU_ENV_VAR_DEFAULT_JWT_SECRET = ""
NOVU_ENV_VAR_DEFAULT_STORE_ENCRYPTION_KEY = ""
NOVU_ENV_VAR_DEFAULT_SENTRY_DSN = ""
NOVU_ENV_VAR_DEFAULT_NEW_RELIC_APP_NAME = ""
NOVU_ENV_VAR_DEFAULT_NEW_RELIC_LICENSE_KEY = ""
NOVU_ENV_VAR_DEFAULT_API_CONTEXT_PATH = ""

def run(plan, args):
    redis_run_output = redis_module.run(plan, args)
    plan.print(redis_run_output)

    mongodb_env_vars = {
        "user": "root",
        "password": "example",
        "image": MONGODB_IMAGE,
        MONGODB_NAME_ARG: MONGODB_NAME,
        "env_vars": {
            "PUID": "1000",
            "PGID": "1000",
        }}
    mongodb_module_output = mongodb_module.run(plan, mongodb_env_vars)
    mongodb_url = mongodb_module_output.url

    # Add Novu API
    novu_api_service = plan.add_service(
        name=NOVU_API_SERVICE_NAME,
        config=ServiceConfig(
            image=NOVU_API_IMAGE,
            ports={
                NOVO_API_PORT_NAME: PortSpec(
                    number=NOVU_API_DEFAULT_PORT,
                    application_protocol=NOVU_API_PROTOCOL_NAME,
                    wait=WAIT_DISABLE,
                ),
            },
            env_vars={
                "NODE_ENV": NOVU_NODE_ENV,
                "MONGO_URL": mongodb_url,
                "REDIS_HOST": redis_run_output["hostname"],
                "REDIS_PORT": str(redis_run_output["client-port"]),
                "REDIS_DB_INDEX": str(NOVU_REDIS_DB_INDEX),
                "PORT": str(NOVU_API_DEFAULT_PORT),
                "DISABLE_USER_REGISTRATION": "false"
            },
            # public_ports={
            #     NOVO_API_PORT_NAME: PortSpec(number=NOVU_API_DEFAULT_PORT),
            # }
        ),
    )

    plan.print(novu_api_service)

    # Add Novu Worker Service
    novu_worker_service = plan.add_service(
        name=NOVU_WORKER_SERVICE_NAME,
        config=ServiceConfig(
            image=NOVU_WORKER_IMAGE,
            env_vars={
                "NODE_ENV": NOVU_NODE_ENV,
                "MONGO_URL": mongodb_url,
                "REDIS_HOST": redis_run_output["hostname"],
                "REDIS_PORT": str(redis_run_output["client-port"]),
                "REDIS_DB_INDEX": str(NOVU_REDIS_DB_INDEX),
                "REDIS_CACHE_SERVICE_HOST": redis_run_output["hostname"],
                "REDIS_CACHE_SERVICE_PORT": str(redis_run_output["client-port"]),
                "S3_LOCAL_STACK": "http://localhost:4566",
                "S3_BUCKET_NAME": "novu-local",
                "S3_REGION": "us-east-1",
                "AWS_ACCESS_KEY_ID": "test",
                "AWS_SECRET_ACCESS_KEY": "test",
                "STORE_ENCRYPTION_KEY": "<ENCRYPTION_KEY_MUST_BE_32_LONG>",
                "SENTRY_DSN": "",
                "NEW_RELIC_APP_NAME": "",
                "NEW_RELIC_LICENSE_KEY": "",
            }
        ),
    )

    # Add Novu WS Service
    novu_ws_service = plan.add_service(
        name=NOVU_WS_SERVICE_NAME,
        config=ServiceConfig(
            image=NOVU_WS_IMAGE,
            ports={
                NOVO_WS_PORT_NAME: PortSpec(
                    number=NOVU_WS_PORT,
                    application_protocol=NOVU_WS_PROTOCOL_NAME,
                    wait=WAIT_DISABLE,
                ),
            },
            env_vars={
                "PORT": str(NOVU_API_DEFAULT_PORT),
                "NODE_ENV": NOVU_NODE_ENV,
                "MONGO_URL": mongodb_url,
                "REDIS_HOST": redis_run_output["hostname"],
                "REDIS_PORT": str(redis_run_output["client-port"]),
            },
            # public_ports={
            #     NOVO_WS_PORT_NAME: PortSpec(number=NOVU_WS_PORT),
            # }
        ),
    )
    ws_url = getUrl(novu_ws_service, NOVO_WS_PORT_NAME)
    api_root_url = getUrl(novu_api_service, NOVO_API_PORT_NAME)

    # Add Novu Widget Service (depends on Nuvo WS service)
    novu_widget_service = plan.add_service(
        name=NOVU_WIDGET_SERVICE_NAME,
        config=ServiceConfig(
            image=NOVU_WIDGET_IMAGE,
            ports={
                NOVO_WIDGET_PORT_NAME: PortSpec(
                    number=NOVU_WIDGET_PORT,
                    application_protocol=NOVU_WIDGET_PROTOCOL_NAME,
                    wait=WAIT_DISABLE,
                ),
            },
            env_vars={
                "REACT_APP_API_URL": api_root_url,
                "REACT_APP_WS_URL": ws_url,
                "REACT_APP_ENVIRONMENT": NOVU_NODE_ENV,
                "WIDGET_CONTEXT_PATH": NOVU_WIDGET_CONTEXT_PATH,
            },
            # public_ports={
            #     NOVO_WIDGET_PORT_NAME: PortSpec(number=NOVU_WIDGET_PORT),
            # }
        ),
    )
    widget_url = getUrl(novu_widget_service, NOVO_WIDGET_PORT_NAME)

    # Add Novu Embed Service
    novu_embed_service = plan.add_service(
        name=NOVU_EMBED_SERVICE_NAME,
        config=ServiceConfig(
            image=NOVU_EMBED_IMAGE,
            ports={
                NOVO_EMBED_PORT_NAME: PortSpec(
                    number=NOVU_EMBED_PORT,
                    application_protocol=NOVU_EMBED_PROTOCOL_NAME,
                    wait=WAIT_DISABLE,
                ),
            },
            env_vars={
                "WIDGET_URL": widget_url,
            },
            # public_ports={
            #     NOVO_EMBED_PORT_NAME: PortSpec(number=NOVU_EMBED_PORT),
            # }
        ),
    )

    widget_embed_url = getUrl(novu_embed_service, NOVO_EMBED_PORT_NAME)
    widget_embed_path = widget_embed_url + "/embed.umd.min.js"
    plan.print(api_root_url)

    # # Add Novu Web Service
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
                "REACT_APP_API_URL": api_root_url,
                "REACT_APP_ENVIRONMENT": NOVU_NODE_ENV,
                "REACT_APP_WIDGET_EMBED_PATH": widget_embed_path,
                "REACT_APP_DOCKER_HOSTED_ENV": NOVU_DOCKER_HOSTED,
                "REACT_APP_WS_URL": ws_url,
            },
        ),
    )

    return


def getUrl(service, port_name):
    return "%s://%s:%d" % (
    service.ports[port_name].application_protocol, service.hostname, service.ports[port_name].number)
