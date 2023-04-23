# custom_options.cfg
# Customizable Server Options
Lines starting with `#` are ignored.
Anything to the right of `;` is ignored on a line.
If the same option is configured twice, the version of the option later in the file will override the earlier one
#### Example
	town_name = english
	landscape = temperate
	town_name = french
Will result in `french` as the setting for `town_name`
## Forcing Default Values
If you want to force a default value for an option, set its value to `_`
It's easier to just remove the setting from this config though
#### Example
	landscaping = _ ; Will force the default value for `landscaping`

## Static Options
Add an option here to override the default values in openttd.cfg

#### Example:
	map_x = 9 ; will the generated map to always be 2^9=512 tiles long

	landscape = tropic ; will force the map to always have the `tropic` biome

## Random Options
If you want it to be randomized, set the value to a list of possible values enclosed in angle brackets `<>`.
### Lists of Choices
If you want to select one of a pre-defined list of settings for an option, separate the values with commas.

#### Example
	variety = <0,2,4> ; Will allow TerraGenesis to have `none`,`low`,or `high` variety.
Note that the `variety` option only takes effect if `land_generator` is set to `1`.

	terrain = <arctic,toyland>`; Will allow the game to select `arctic` or `toyland` terrains when generating a map

### Numeric Options
 Numeric ranges can be expressed as `<a..b>`. If you only want certain numbers, just list them with commas
#### Example:
	map_x = <6..12> ; will let the game randomize the X dimension of the map to be any integer from 6 to 12, allowing the X dimension to be any power of two between 64 and 4096

### True/False options
For true/false options, you can list them as `<true,false>` like a normal listed option, or use `<bool>` to randomly select 'true' or 'false' for that setting
#### Example:
	bribe = <bool>
	bribe = <true,false>
Both of these will have the same effect of randomly selecting `true` or `false` for the bribary setting
## Invalid Options
The script parsing this config does no input validation. If the right side of the `=` has something not enclosed in angle brackets, or an underscore, it will be interpreted literally

#### Example
	terrain = (alpine,toyland) ; This will write `terrain = (alpine,toyland)` to the config file loaded by the game process

	starting_year = <-1000...3000> ; This will try to pick a random starting year between -1000 and 3000

    herpderp = boatmurdered ; This will be ignored because there is no `herpderp` option in openttd.cfg
