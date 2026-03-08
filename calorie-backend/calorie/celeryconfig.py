import constants

timezone = 'UTC'

## Broker settings.
broker_url = "amqp://" + constants.RABBITMQ_DEFAULT_USER + ":" + constants.RABBITMQ_DEFAULT_PASS + "@rabbitmq:5672"

# List of modules to import when the Celery worker starts.
imports = ('calorie',)

## Using the database to store task state and results.
result_backend = 'rpc://'
result_persistent = True

broker_connection_retry = True
broker_connection_retry_on_startup = True

task_routes = {
    'calorie.demo': {'queue' : 'calorie'},
}
