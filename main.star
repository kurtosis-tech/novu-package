redis_module = import_module("github.com/kurtosis-tech/redis-package/main.star")
mongodb_module = import_module("github.com/kurtosis-tech/mongodb-package/main.star")

# NOVU shared settings
NOVU_VERSION = "0.14.0"

# Redis
NOVU_REDIS_PORT = 6379
NOVU_REDIS_CACHE_SERVICE_PORT = 6379
NOVU_REDIS_DB_INDEX = 2

# MongoDB
MONGODB_IMAGE = "mongo:latest"
MONGODB_NAME_ARG = "name"
MONGODB_SERVICE_NAME = "mongodb"
MONGODB_ROOT_USERNAME = "root"
MONGODB_ROOT_PASSWORD = "password"
NOVU_MONGO_USERNAME = "novu"
NOVU_MONGO_PASSWORD = "novu"
NOVU_MONGODB_DB_NAME = "novu-db"

# NOVU API
NOVU_API_IMAGE = "ghcr.io/novuhq/novu/api:0.14.0"
NOVU_API_SERVICE_NAME = "novu-api"
NOVU_API_PORT_NAME = "novu-api-port"
NOVU_API_PROTOCOL_NAME = "http"
NOVU_API_PORT = 3000

# WORKER
NOVU_WORKER_IMAGE = "ghcr.io/novuhq/novu/worker:%s" % NOVU_VERSION
NOVU_WORKER_SERVICE_NAME = "novu-worker"

# NOVU WS
NOVU_WS_IMAGE = "ghcr.io/novuhq/novu/ws:%s" % NOVU_VERSION
NOVU_WS_SERVICE_NAME = "novu-ws"
NOVU_WS_PROTOCOL_NAME = "ws"
NOVO_WS_PORT_NAME = NOVU_WS_SERVICE_NAME
NOVU_WS_PORT = 3002

# NOVU Widget
NOVU_WIDGET_IMAGE = "ghcr.io/novuhq/novu/widget:%s" % NOVU_VERSION
NOVU_WIDGET_SERVICE_NAME = "novu-widget"
NOVO_WIDGET_PORT_NAME = NOVU_WIDGET_SERVICE_NAME
NOVU_WIDGET_PROTOCOL_NAME = "http"
NOVU_WIDGET_PORT = 4500

# NOVU Embed
NOVU_EMBED_IMAGE = "ghcr.io/novuhq/novu/embed:%s" % NOVU_VERSION
NOVU_EMBED_SERVICE_NAME = "novu-embed"
NOVO_EMBED_PORT_NAME = NOVU_EMBED_SERVICE_NAME
NOVU_EMBED_PROTOCOL_NAME = "http"
NOVU_EMBED_PORT = 4701

# NOVU Web
NOVU_WEB_IMAGE = "ghcr.io/novuhq/novu/web:%s" % NOVU_VERSION
NOVU_WEB_SERVICE_NAME = "novu-web"
NOVO_WEB_PORT_NAME = NOVU_WEB_SERVICE_NAME
NOVU_WEB_PROTOCOL_NAME = "http"
NOVU_WEB_PORT = 4200

# NOVU shared settings
NOVU_DOCKER_HOSTED = "true"
NOVU_NODE_ENV = "local"
NOVU_WIDGET_CONTEXT_PATH = ""
NOVU_DISABLE_USER_REGISTRATION = "false"
NOVU_FRONT_BASE_URL = "http://client:%d" % NOVU_WEB_PORT
NOVU_DEFAULT_S3_LOCAL_STACK = "http://localhost:4566"
NOVU_DEFAULT_S3_BUCKET_NAME = "novu-local"
NOVU_DEFAULT_S3_REGION = "us-east-1"
NOVU_DEFAULT_AWS_ACCESS_KEY_ID = "test"
NOVU_DEFAULT_AWS_SECRET_ACCESS_KEY = "test"
NOVU_DEFAULT_JWT_SECRET = "your-secret"
NOVU_DEFAULT_WS_CONTEXT_PATH = ""
NOVU_DEFAULT_STORE_ENCRYPTION_KEY = "<ENCRYPTION_KEY_MUST_BE_32_LONG>"
NOVU_DEFAULT_SENTRY_DSN = ""
NOVU_DEFAULT_NEW_RELIC_APP_NAME = ""
NOVU_DEFAULT_NEW_RELIC_LICENSE_KEY = ""
NOVU_DEFAULT_API_CONTEXT_PATH = ""

ENABLE_HEALTH_CHECK = True
DEFAULT_HEALTH_CHECK_TIMEOUT = "120s"
WAIT_DISABLE = None


def run(plan, args):
    health_check_enabled = args.get("health_check", ENABLE_HEALTH_CHECK)
    plan.print("Running with health-check: %s" %health_check_enabled)

    redis_run_output = redis_module.run(plan, args)
    redis_host = redis_run_output["hostname"]
    redis_port = str(redis_run_output["client-port"])
    redis_db_index = str(NOVU_REDIS_DB_INDEX)
    plan.print(redis_run_output)

    mongodb_url = startMongoDB(plan)

    # Add Novu API
    novu_api_service = plan.add_service(
        name=NOVU_API_SERVICE_NAME,
        config=ServiceConfig(
            image=NOVU_API_IMAGE,
            ports={
                NOVU_API_PORT_NAME: PortSpec(
                    number=NOVU_API_PORT,
                    application_protocol=NOVU_API_PROTOCOL_NAME,
                    wait=WAIT_DISABLE,
                ),
            },
            env_vars={
                "NODE_ENV": NOVU_NODE_ENV,
                "API_ROOT_URL": "",
                "DISABLE_USER_REGISTRATION": NOVU_DISABLE_USER_REGISTRATION,
                "PORT": str(NOVU_API_PORT),
                "FRONT_BASE_URL": NOVU_FRONT_BASE_URL,
                "MONGO_URL": mongodb_url,
                "REDIS_HOST": redis_host,
                "REDIS_PORT": redis_port,
                "REDIS_DB_INDEX": redis_db_index,
                "REDIS_CACHE_SERVICE_HOST": redis_host,
                "REDIS_CACHE_SERVICE_PORT": redis_port,
                "S3_LOCAL_STACK": NOVU_DEFAULT_S3_LOCAL_STACK,
                "S3_BUCKET_NAME": NOVU_DEFAULT_S3_BUCKET_NAME,
                "S3_REGION": NOVU_DEFAULT_S3_REGION,
                "AWS_ACCESS_KEY_ID": NOVU_DEFAULT_AWS_ACCESS_KEY_ID,
                "AWS_SECRET_ACCESS_KEY": NOVU_DEFAULT_AWS_SECRET_ACCESS_KEY,
                "JWT_SECRET": NOVU_DEFAULT_JWT_SECRET,
                "STORE_ENCRYPTION_KEY": NOVU_DEFAULT_STORE_ENCRYPTION_KEY,
                "SENTRY_DSN": NOVU_DEFAULT_SENTRY_DSN,
                "NEW_RELIC_APP_NAME": NOVU_DEFAULT_NEW_RELIC_APP_NAME,
                "NEW_RELIC_LICENSE_KEY": NOVU_DEFAULT_NEW_RELIC_LICENSE_KEY,
                "API_CONTEXT_PATH": NOVU_DEFAULT_API_CONTEXT_PATH
            },
            public_ports={
                NOVU_API_PORT_NAME: PortSpec(number=NOVU_API_PORT),
            }
        ),
    )
    api_root_url = getUrl(novu_api_service, NOVU_API_PORT_NAME)

    # Add Novu Worker Service
    novu_worker_service = plan.add_service(
        name=NOVU_WORKER_SERVICE_NAME,
        config=ServiceConfig(
            image=NOVU_WORKER_IMAGE,
            env_vars={
                "NODE_ENV": NOVU_NODE_ENV,
                "MONGO_URL": mongodb_url,
                "REDIS_HOST": redis_host,
                "REDIS_PORT": redis_port,
                "REDIS_DB_INDEX": redis_db_index,
                "REDIS_CACHE_SERVICE_HOST": redis_host,
                "REDIS_CACHE_SERVICE_PORT": redis_port,
                "S3_LOCAL_STACK": NOVU_DEFAULT_S3_LOCAL_STACK,
                "S3_BUCKET_NAME": NOVU_DEFAULT_S3_BUCKET_NAME,
                "S3_REGION": NOVU_DEFAULT_S3_REGION,
                "AWS_ACCESS_KEY_ID": NOVU_DEFAULT_AWS_ACCESS_KEY_ID,
                "AWS_SECRET_ACCESS_KEY": NOVU_DEFAULT_AWS_SECRET_ACCESS_KEY,
                "JWT_SECRET": NOVU_DEFAULT_JWT_SECRET,
                "STORE_ENCRYPTION_KEY": NOVU_DEFAULT_STORE_ENCRYPTION_KEY,
                "SENTRY_DSN": NOVU_DEFAULT_SENTRY_DSN,
                "NEW_RELIC_APP_NAME": NOVU_DEFAULT_NEW_RELIC_APP_NAME,
                "NEW_RELIC_LICENSE_KEY": NOVU_DEFAULT_NEW_RELIC_LICENSE_KEY,
                "API_CONTEXT_PATH": NOVU_DEFAULT_API_CONTEXT_PATH
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
                "PORT": str(NOVU_WS_PORT),
                "NODE_ENV": NOVU_NODE_ENV,
                "MONGO_URL": mongodb_url,
                "REDIS_HOST": redis_host,
                "REDIS_PORT": redis_port,
                "WS_CONTEXT_PATH": NOVU_DEFAULT_WS_CONTEXT_PATH,
                "JWT_SECRET": NOVU_DEFAULT_JWT_SECRET
            },
            public_ports={
                NOVO_WS_PORT_NAME: PortSpec(number=NOVU_WS_PORT),
            }
        ),
    )
    ws_url = getUrl(novu_ws_service, NOVO_WS_PORT_NAME)

    # Add Novu Widget Service (depends on Novu WS service)
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
            }
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
            }
            ,
            public_ports={
                NOVO_EMBED_PORT_NAME: PortSpec(number=NOVU_EMBED_PORT),
            }
        ),
    )

    # Create the web service using URLs that are accessible from outside the enclace
    host = "localhost"
    react_app_api_url = "http://%s:%d" % (host, NOVU_API_PORT)
    react_app_ws_url = "http://%s:%d" % (host, NOVU_WS_PORT)
    react_app_widget_embed_path = "http://%s:%d/embed.umd.min.js" % (host, NOVU_EMBED_PORT)

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
                "REACT_APP_API_URL": react_app_api_url,
                "REACT_APP_ENVIRONMENT": NOVU_NODE_ENV,
                "REACT_APP_WIDGET_EMBED_PATH": react_app_widget_embed_path,
                "REACT_APP_DOCKER_HOSTED_ENV": NOVU_DOCKER_HOSTED,
                "REACT_APP_WS_URL": react_app_ws_url,
            },
            public_ports={
                NOVO_WEB_PORT_NAME: PortSpec(number=NOVU_WEB_PORT),
            }
        ),
    )
    plan.print("The web configuration can be accessed on: http://%s:%s" % (host, NOVU_WEB_PORT))

    if health_check_enabled:
        plan.print("Health check enabled, probing for API to become available...")
        # It can take a while for all containers to complete the initialization, so we wait for the API to become healthy:
        api_health_check_recipe = GetHttpRequestRecipe(
            port_id=NOVU_API_PORT_NAME,
            endpoint="/v1/health-check",
        )

        plan.wait(
            service_name=NOVU_API_SERVICE_NAME,
            recipe=api_health_check_recipe,
            field="code",
            assertion="==",
            target_value=200,
            timeout=DEFAULT_HEALTH_CHECK_TIMEOUT,
        )
    else:
        plan.print("Health-check disabled.")

    plan.print("All services successfully initialized!")

    return


def startMongoDB(plan):
    mongodb_env_vars = {
        "user": MONGODB_ROOT_USERNAME,
        "password": MONGODB_ROOT_PASSWORD,
        "image": MONGODB_IMAGE,
        MONGODB_NAME_ARG: MONGODB_SERVICE_NAME,
        "env_vars": {
            "PUID": "1000",
            "PGID": "1000",
        }}
    mongodb_module_output = mongodb_module.run(plan, mongodb_env_vars)
    mongodb_service_port = mongodb_module_output.service.ports['mongodb'].number
    mongodb_url = "mongodb://%s:%s@%s:%d/%s" % (
        NOVU_MONGO_USERNAME,
        NOVU_MONGO_PASSWORD,
        MONGODB_SERVICE_NAME,
        mongodb_service_port,
        NOVU_MONGODB_DB_NAME
    )
    plan.print(mongodb_url)

    mongodb_local_url = "mongodb://localhost:%d/%s" % (mongodb_service_port, NOVU_MONGODB_DB_NAME)
    # create user
    command_create_user = "db.getSiblingDB('%s').createUser({user:'%s', pwd:'%s', roles:[{role:'readWrite',db:'%s'}]});" % (
        NOVU_MONGODB_DB_NAME, NOVU_MONGO_USERNAME, NOVU_MONGO_PASSWORD, NOVU_MONGODB_DB_NAME
    )
    exec_create_user = ExecRecipe(
        command=[
            "mongosh",
            "-u",
            MONGODB_ROOT_USERNAME,
            "-p",
            MONGODB_ROOT_PASSWORD,
            "-eval",
            command_create_user
        ],
    )
    plan.wait(
        service_name=mongodb_module_output.service.name,
        recipe=exec_create_user,
        field="code",
        assertion="==",
        target_value=0,
        timeout="30s",
    )

    command_create_collection = "db.getSiblingDB('%s').createCollection('%s');" % (
        NOVU_MONGODB_DB_NAME, NOVU_MONGODB_DB_NAME
    )
    exec_create_collection = ExecRecipe(
        command=[
            "mongosh",
            mongodb_local_url,
            "-u",
            NOVU_MONGO_USERNAME,
            "-p",
            NOVU_MONGO_PASSWORD,
            "-eval",
            command_create_collection
        ],
    )
    plan.wait(
        service_name=mongodb_module_output.service.name,
        recipe=exec_create_collection,
        field="code",
        assertion="==",
        target_value=0,
        timeout="30s",
    )
    return mongodb_url


def getUrl(service, port_name):
    return "%s://%s:%d" % (
        service.ports[port_name].application_protocol, service.hostname, service.ports[port_name].number)
