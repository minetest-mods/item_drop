unused_args = false
allow_defined_top = true
max_line_length = 999

ignore = {
    "name", "drops", "i",
}

globals = {
    "minetest",
}

read_globals = {
    string = {fields = {"split", "trim"}},
    table = {fields = {"copy", "getn"}},

    "vector", "ItemStack",
    "dump",
}
