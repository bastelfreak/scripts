#!/bin/bash
# written by Tim Meusel
# this is needed after every 'pip install --upgrade pycurl'
pip uninstall pycurl; PYCURL_SSL_LIBRARY=nss pip install pycurl
