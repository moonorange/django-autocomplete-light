#!/bin/bash

set -x

WORKSPACE="${WORKSPACE:-$(pwd)}"
CLEAN_VIRTUALENV="${CLEAN_VIRTUALENV:-0}"
DJANGO_TAGGIT="${DJANGO_TAGGIT:-1}"
DJANGO_GENERIC_M2M="${DJANGO_GENERIC_M2M:-1}"
PYTHON_VERSION="${PYTHON_VERSION:-3.3}"
DJANGO_VERSION="${DJANGO_VERSION:-1.5}"
export DATABASE_NAME="autocomplete_light_test_${BUILD_ID}${DJANGO_VERSION}${DJANGO_TAGGIT}${PYTHONVERSION}${DJANGO_GENERIC_M2M}"
export DATABASE_NAME="${DATABASE_NAME//[._-]}"

function clean {
    psql -c "drop database if exists $DATABASE_NAME;" -U postgres
}
trap 'clean; exit' SIGINT SIGQUIT

# Make a unique env path for this configuration
ENV_PATH="$WORKSPACE/test_env"

psql -c "drop database if exists $DATABASE_NAME;" -U postgres
psql -c "create database $DATABASE_NAME;" -U postgres

# Get real django version
[ "$DJANGO_VERSION" = "1.4" ] && DJANGO_VERSION="1.4.10"
[ "$DJANGO_VERSION" = "1.5" ] && DJANGO_VERSION="1.5.5"
[ "$DJANGO_VERSION" = "1.6" ] && DJANGO_VERSION="1.6"

# Clean virtualenv if necessary
[ "$CLEAN_VIRTUALENV" = "1" ] && rm -rf $ENV_PATH

# Make virtualenv if necessary
[ ! -d "$ENV_PATH" ] && virtualenv-$PYTHON_VERSION $ENV_PATH

# Shebangs are too long without this and the kernel truncates them at 127
# characters.
virtualenv-$PYTHON_VERSION --relocatable $ENV_PATH

source $ENV_PATH/bin/activate

[ "$DJANGO_TAGGIT" = "1" ] && DJANGO_TAGGIT=django-taggit || DJANGO_TAGGIT=""

[ "$DJANGO_GENERIC_M2M" = "1" ] && DJANGO_GENERIC_M2M=django-generic-m2m || DJANGO_GENERIC_M2M=""

pip install $DJANGO_TAGGIT $DJANGO_GENERIC_M2M \
    -e $WORKSPACE \
    -r $WORKSPACE/test_project/requirements.txt \
    -r $WORKSPACE/test_project/test_requirements.txt \
    django==$DJANGO_VERSION

cd $WORKSPACE
test_project/manage.py jenkins autocomplete_light --liveserver=localhost:9000-9200 --settings=test_project.settings_postgres

clean
