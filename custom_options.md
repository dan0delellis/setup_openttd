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
	map_x = <6..12> ; will let the game randomize the X dimension of the map to be any integer from 6 to 12

### True/False options
For true/false options, you can list them as `<true,false>` like a normal listed option, or use `<bool>` to randomly select 'true' or 'false' for that setting
#### Example:
	bribe = <bool>
	bribe = <true,false>
Both of these will have the same effect of randomly selecting `true` or `false` for the bribary setting
### Multi-Option Contraints
This only works for numeric options. If you want the sum of two options to be limited, you can define that by enclosing in angle brackets an option of the form 'shuffler.opt_1+opt_2' and then the desired value for the sum of those two options.
Note that this requires you to define the ranges of the two options you want to adjust for. If you try to limit two unconfigured options, it will just cause the shuffler to crash. It also requires that there be some overlap between what sum you want and what sums are actually possible.

Currently it only supports addition, but I suppose there's nothing stopping me from implementing any inversible binary operation. It will only ever support two options per contraint though.

####Example:
    map_x = <8..12> ; map_x will be between 8 and 12
    map_y = <6..10> ; map_y will be between 6 and 10
    <shuffler.map_x+map_y> = <18..24> ; If the generated value of map_x + map_y is not between 18 and 24, one or both options will be reshuffled

Multi-option constraints are processed after all normal options generated. A multi-option constraint can be defined anywhere in the file. Like normal options, if you set it twice in the file, the one later in the file will overwrite the one higher up.

While there is nothing stopping you from using the same option in multiple constraints, doing so may have unintended consequences.

####Example:
    map_x = <6..12>
    map_y = <6..12>
    industry_density = <0..5>
    <shuffler.map_x+map_y> = 14
    <shuffler.industry_density+map_x> = 10
Doing this will force the sum of map_x+map_y to be exactly 14. However, the 2nd shuffler option may cause a new value for map_x to be picked, if the generated option for industry_density doesn't add to 10 with the previously picked value for map_x.

## Invalid Options
The script parsing this config does no input validation. If the right side of the `=` has something not enclosed in angle brackets, or an underscore, it will be interpreted literally

#### Example
	terrain = (alpine,toyland) ; This will write `terrain = (alpine,toyland)` to the config file loaded by the game process

	starting_year = <-1000...3000> ; This will try to pick a random starting year between -1000 and 3000

    herpderp = boatmurdered ; This will be ignored because there is no `herpderp` option in openttd.cfg

    <shuffler.number_towns+industry_density> = 8 ; This set of options will cause the shuffler to crash
    number_towns = <0,2,4>                       ; Because 8 is not a possible sum given the choices
    industry_density = <1,3,5>                   ; of (0,2,or 4) plus (1,3,or 5). (1,3,5,7,9) are the only possible sums

    map_x = _   ; Use default
    map_y = _   ; Use default
    <shuffler.map_x+map_y> = 17 ; This will cause the shuffler to crash, because it has no way of knowing what range of numbers to pick for map_x and map_y
