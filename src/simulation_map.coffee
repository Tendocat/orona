###
Orona, © 2010 Stéphan Kochen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
###

{round, random,
 floor}            = Math
{TILE_SIZE_WORLD,
 TILE_SIZE_PIXELS} = require './constants'
{Map, MapCell,
 TERRAIN_TYPES}    = require './map'
net                = require './net'


TERRAIN_TYPE_ATTRIBUTES =
  '|': { tankSpeed:  0, tankTurn: 0.00, manSpeed:  0 }
  ' ': { tankSpeed:  3, tankTurn: 0.25, manSpeed:  0 }
  '~': { tankSpeed:  3, tankTurn: 0.25, manSpeed:  4 }
  '%': { tankSpeed:  3, tankTurn: 0.25, manSpeed:  4 }
  '=': { tankSpeed: 16, tankTurn: 1.00, manSpeed: 16 }
  '#': { tankSpeed:  6, tankTurn: 0.50, manSpeed:  8 }
  ':': { tankSpeed:  3, tankTurn: 0.25, manSpeed:  4 }
  '.': { tankSpeed: 12, tankTurn: 1.00, manSpeed: 16 }
  '}': { tankSpeed:  0, tankTurn: 0.00, manSpeed:  0 }
  'b': { tankSpeed: 16, tankTurn: 1.00, manSpeed: 16 }
  '^': { tankSpeed:  3, tankTurn: 0.50, manSpeed:  0 }

extendTerrainMap = ->
  for ascii, attributes of TERRAIN_TYPE_ATTRIBUTES
    type = TERRAIN_TYPES[ascii]
    for key, value of attributes
      type[key] = value

extendTerrainMap()


class SimulationMapCell extends Map::CellClass
  getTankSpeed: (tank) ->
    # Check for a pillbox.
    return 0 if @pill?.armour > 0
    # Check for an enemy base.
    if @base?.owner?
      return 0 unless @base.owner == tank or tank.isAlly(@base.owner) or @base.armour <= 9
    # Check if we're on a boat.
    return 16 if tank.onBoat and @isType('^', ' ')
    # Take the land speed.
    @type.tankSpeed

  getTankTurn: (tank) ->
    # Check for a pillbox.
    return 0.00 if @pill?.armour > 0
    # Check for an enemy base.
    if @base?.owner?
      return 0.00 unless @base.owner == tank or tank.isAlly(@base.owner) or @base.armour <= 9
    # Check if we're on a boat.
    return 1.00 if tank.onBoat and @isType('^', ' ')
    # Take the land turn speed.
    @type.tankTurn

  getManSpeed: (man) ->
    {tank} = man
    # Check for a pillbox.
    return 0 if @pill?.armour > 0
    # Check for an enemy base.
    if @base?.owner?
      return 0 unless @base.owner == tank or tank.isAlly(@base.owner) or @base.armour <= 9
    # Check if we're on a boat.
    return 16 if man.onBoat and @isType('^', ' ')
    # Take the land speed.
    @type.manSpeed

  setType: (newType, mine, retileRadius) ->
    oldType = @type; hadMine = @mine
    super
    net.mapChanged this, oldType, hadMine


class SimulationMap extends Map
  CellClass: SimulationMapCell

  # Get the cell at the given pixel coordinates, or return a dummy cell.
  cellAtPixel: (x, y) ->
    @cellAtTile floor(x / TILE_SIZE_PIXELS), floor(y / TILE_SIZE_PIXELS)

  # Get the cell at the given world coordinates, or return a dummy cell.
  cellAtWorld: (x, y) ->
    @cellAtTile floor(x / TILE_SIZE_WORLD), floor(y / TILE_SIZE_WORLD)

  getRandomStart: ->
    @starts[round(random() * (@starts.length - 1))]


# Exports.
exports.SimulationMapCell = SimulationMapCell
exports.SimulationMap = SimulationMap