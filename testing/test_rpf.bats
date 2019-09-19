#!/usr/bin/env bats
#
# Automated testing of `rpf' script
#
# Dependencies:
#   bats (https://github.com/bats-core/bats-core)
#
# TODO: When new profile is created, test expected output msg.
# TODO: Test expected error messages.
#

__name=$(basename "${BATS_TEST_FILENAME}")

rpf_exec="${BATS_TEST_DIRNAME}/../rpf"
rpf_config_dir="${HOME}/.rpf"
rpf_config_dir_bak="${HOME}/.rpf_tmp_backup"
rpf_profiles_dir="${rpf_config_dir}/profiles"
rpf_shared_dir="${rpf_config_dir}/shared"


#
# Fixtures
#

# If script crushes during execution (e.g. because of software or hardware
# failure), ensure, that temporary backup of existing rpf config dir
# is not overwriten.
if [ -d "${rpf_config_dir_bak}" ]; then
    echo "${__name}: aborting: other ${rpf_config_dir_bak} already exists" >&2
    echo "Remove ${rpf_config_dir_bak} manually" >&2
    exit 1
fi


setup() {
    # Backup existing rpf config dir.
    # teardown() deletes rpf config dir automatically!
    if [ -d "${rpf_config_dir}" ]; then
        mv --backup "${rpf_config_dir}" "${rpf_config_dir_bak}"
    fi
}


teardown() {
    # Delete test data and restore config dir backup (if there is any).
    if [ -d "${rpf_config_dir}" ]; then
        rm -r "${rpf_config_dir}"
    fi
    if [ -d "${rpf_config_dir_bak}" ]; then
        mv --backup "${rpf_config_dir_bak}" "${rpf_config_dir}"
    fi
}


#
# Tests
#


# Call rpf without arguments:
#
# Tests:
#   call rpf without any option -> show help, exit 1

@test "show help when invoking rpf without arguments" {
    run "${rpf_exec}"
    [ "${status}" -eq 1 ]
    [ "${lines[0]}" = "Usage: rpf [OPTION...] PROFILE_NAME" ]
}


# Call rpf help option
#
# Tests:
#   call rpf with short option -> show help, exit 0
#   call rpf with long option -> show help, exit 0
#   call rpf with help option and another extra params -> error msg, exit 1

@test "show help" {
    # test short option
    run "${rpf_exec}" -h
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "Usage: rpf [OPTION...] PROFILE_NAME" ]

    # test long option
    run "${rpf_exec}" --help
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "Usage: rpf [OPTION...] PROFILE_NAME" ]
}


@test "do not allow extra args when calling help" {
    run "${rpf_exec}" -h "extraArg"
    [ "${status}" -eq 1 ]
}


# Create rpf profile
#
# Tests:
#   create valid rpf profile using short option -> all rpf config dirs
#       and profile config files have been created properly, output msg,
#       exit 0
#   create valid rpf profile using long option -> profile has been
#       sucessfully created, output msg, exit 0
#   create rpf profile with empty name -> error msg, exit 1
#   create rpf profile with existing profile name -> error msg, exit 1
#   create rpf profile with unallowed chars in profile name
#       -> error msg, exit 1
#   create rpf profile with another extra params -> error msg, exit 1

@test "create rpf profile" {
    local profile_name_1="createProfile1"
    local profile_dir_1="${rpf_profiles_dir}/${profile_name_1}"
    local profile_name_2="createProfile2"
    local profile_dir_2="${rpf_profiles_dir}/${profile_name_2}"
    local rpf_profile_1_conf="${rpf_profiles_dir}/${profile_name_1}/conf"
    local rpf_profile_1_exclude="${rpf_profiles_dir}/${profile_name_1}/exclude"

    # test short option
    run "${rpf_exec}" -c "${profile_name_1}"
    [ "${status}" -eq 0 ]
    [ -d "${rpf_config_dir}" ]
    [ -d "${rpf_profiles_dir}" ]
    [ -d "${rpf_shared_dir}" ]
    [ -s "${rpf_profile_1_conf}" ]
    [ -s "${rpf_profile_1_exclude}" ]

    # test long option
    run "${rpf_exec}" --create-profile "${profile_name_2}"
    [ "${status}" -eq 0 ]
    [ -d "${profile_dir_2}" ]
}


@test "do not create profile with empty profile name" {
    run "${rpf_exec}" -c
    [ "${status}" -eq 1 ]
}


@test "do not overwrite existing profile" {
    local profile_name="existingProfile"
    local profile_dir="${rpf_profiles_dir}/${profile_name}"

    # create test profile
    run "${rpf_exec}" -c "${profile_name}"
    [ "${status}" -eq 0 ]

    # try to create new profile with existing profile name
    run "${rpf_exec}" -c "${profile_name}"
    [ "${status}" -eq 1 ]
}


@test "restrict chars in profile name" {
    # ASCII special chars
    local forbidden_chars=(' ' '!' '"' '#' '$' '%' '&' "'" '(' ')' '*' '+' \
        ',' '-' '.' '/' ':' ';' '<' '=' '>' '?' '@' '[' '\' ']' '^' '_' '`' \
        '{' '|' '}' '~')

    for char in "${forbidden_chars[@]}"; do
        local profile_name="forbidden${char}profile"
        local profile_dir="${rpf_profiles_dir}/${profile_name}"

        run "${rpf_exec}" -c "${profile_name}"
        [ "${status}" -eq 1 ]
        [ ! -d "${profile_dir}" ]
    done
}


@test "do not allow extra args when creating profile" {
    local profile_name="firstArgCreate"
    local profile_dir="${rpf_profiles_dir}/${profile_name}"

    run "${rpf_exec}" -c "${profile_name}" "extraArg"
    [ "${status}" -eq 1 ]
    [ ! -d "${profile_dir}" ]
}

# Show profile config
#
# Tests:
#   Show profile config of existing profile -> show profile config, exit 0
#   Show profile config using empty name -> error msg, exit 1
#   Show profile config of nonexisting profile -> error msg, exit 1
#   Show profile config of existing profile using another extra params
#       -> error msg, exit 1

@test "show config of existing profile" {
    local profile_name="showProfileConfig"

    # create test profile
    run "${rpf_exec}" -c "${profile_name}"

    # test short option
    run "${rpf_exec}" -s "${profile_name}"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "# rsync config template" ]

    # test long option
    run "${rpf_exec}" --show-profile-config "${profile_name}"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "# rsync config template" ]
}


@test "do not show config of profile with empty profile name" {
    run "${rpf_exec}" -s
    [ "${status}" -eq 1 ]
}


@test "fail when profile name does not exist" {
    local profile_name="nonExistingProfile"

    run "${rpf_exec}" -s "${profile_name}"
    [ "${status}" -eq 1 ]
}


@test "do not allow extra args when showing profile config" {
    local profile_name="firstArgShow"

    # create test profile
    run "${rpf_exec}" -c "${profile_name}"

    run "${rpf_exec}" -s "${profile_name}" "extraArg"
    [ "${status}" -eq 1 ]
}


# List profiles
#
# Tests:
#   List profiles: 0 available -> no output, exit 0
#   List profiles: 1 available -> show available profile, exit 0
#   List profiles (short option): 2 available -> show available profiles,
#       exit 0
#   List profiles (long option): 2 available -> show available profiles,
#       exit 0
#   Call rpf to list available profiles with another extra params
#       -> error msg, exit 1

@test "list profiles: 0 available" {
    run "${rpf_exec}" -l
    [ "${status}" -eq 0 ]
    [ -z "${lines[0]}" ]
}


@test "list profiles: 1 available" {
    local profile_name="singleProfile"

    # create test profile
    run "${rpf_exec}" -c "${profile_name}"

    run "${rpf_exec}" -l
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "${profile_name}" ]
}


@test "list profiles: 2 available" {
    local profile_name_1="profile1"
    local profile_name_2="profile2"

    # create test profiles
    run "${rpf_exec}" -c "${profile_name_1}"
    run "${rpf_exec}" -c "${profile_name_2}"

    # test short option
    run "${rpf_exec}" -l
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "${profile_name_1}" ]
    [ "${lines[1]}" = "${profile_name_2}" ]

    # test long option
    run "${rpf_exec}" --list-profiles
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "${profile_name_1}" ]
    [ "${lines[1]}" = "${profile_name_2}" ]
}


@test "do not allow extra args when listing profiles" {
    local profile_name="firstArgList"

    # create test profile
    run "${rpf_exec}" -c "${profile_name}"

    run "${rpf_exec}" -l "${profile_name}" "extraArg"
    [ "${status}" -eq 1 ]
}
