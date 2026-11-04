#!/bin/bash
pkill -f soong_ui; pkill -x ninja; pkill -f ckati; sleep 3
pgrep -fc 'ninja|soong_ui|ckati'
