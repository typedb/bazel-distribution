#
# Copyright (C) 2022 Vaticle
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

load(":constraints.bzl", "constraint_arm64", "constraint_x86_64", "constraint_linux", "constraint_mac", "constraint_windows",
     "constraint_linux_arm64", "constraint_linux_x86_64", "constraint_mac_arm64", "constraint_mac_x86_64", "constraint_win_x86_64")

config_setting(
    name = "is_linux",
    constraint_values = constraint_linux,
)

config_setting(
    name = "is_mac",
    constraint_values = constraint_mac,
)

config_setting(
    name = "is_windows",
    constraint_values = constraint_windows,
)

config_setting(
    name = "is_arm64",
    constraint_values = constraint_arm64,
)

config_setting(
    name = "is_x86_64",
    constraint_values = constraint_x86_64,
)

config_setting(
    name = "is_linux_arm64",
    constraint_values = constraint_linux_arm64,
)

config_setting(
    name = "is_linux_x86_64",
    constraint_values = constraint_linux_x86_64,
)

config_setting(
    name = "is_mac_arm64",
    constraint_values = constraint_mac_arm64,
)

config_setting(
    name = "is_mac_x86_64",
    constraint_values = constraint_mac_x86_64,
)

config_setting(
    name = "is_windows_x86_64",
    constraint_values = constraint_win_x86_64,
)

platform(
    name = "linux_arm64",
    constraint_values = constraint_linux_arm64,
)

platform(
    name = "linux_x86_64",
    constraint_values = constraint_linux_x86_64,
)

platform(
    name = "mac_arm64",
    constraint_values = constraint_mac_arm64,
)

platform(
    name = "mac_x86_64",
    constraint_values = constraint_mac_x86_64,
)

platform(
    name = "win_x86_64",
    constraint_values = constraint_win_x86_64,
)
