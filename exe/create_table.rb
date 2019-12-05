#!/usr/bin/env ruby
# coding: utf-8
# frozen_string_literal: true

$:.push("lib")
require 'ezframe'
require 'sequel'

Ezframe::Model.make_base
model = Ezframe::Model.get_clone
model.create_tables
