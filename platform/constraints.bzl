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

constraint_linux = [
    "@platforms//os:linux",
]

constraint_mac = [
    "@platforms//os:osx",
]

constraint_windows = [
    "@platforms//os:windows",
]

constraint_arm64 = [
    "@platforms//cpu:arm64",
]

constraint_x86_64 = [
    "@platforms//cpu:x86_64",
]

constraint_linux_x86_64 = constraint_linux + constraint_x86_64
constraint_linux_arm64 = constraint_linux + constraint_arm64
constraint_mac_x86_64 = constraint_mac + constraint_x86_64
constraint_mac_arm64 = constraint_mac + constraint_arm64
constraint_win_x86_64 = constraint_windows + constraint_x86_64
