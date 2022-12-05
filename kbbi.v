module main

import cli
import client
import format { format_result }
import json
import os
import spinner
import term
import v.vmod

fn create_client(c client.KbbiClientConfig) ?client.KbbiClient {
	return client.new_client_from_login(
		base: c
		username: os.getenv_opt('KBBI_USERNAME')?
		password: os.getenv_opt('KBBI_PASSWORD')?
	)!
}

fn main() {
	vm := vmod.decode(@VMOD_FILE) or { panic(err) }
	mut app := cli.Command{
		name: vm.name
		usage: '<word>...'
		description: vm.description
		version: vm.version
		posix_mode: true
		flags: [
			cli.Flag{
				flag: cli.FlagType.bool
				name: 'no-color'
				description: 'Disables output color.'
				global: true
			},
			cli.Flag{
				flag: cli.FlagType.bool
				name: 'no-cache'
				description: 'Ignores cached response.'
				global: true
			},
			cli.Flag {
				flag: cli.FlagType.bool
				name: 'json'
				description: 'Outputs in JSON format.'
			}
		]
		required_args: 1
		execute: fn (cmd cli.Command) ! {
			shared spinner_state := spinner.State{}
			spinner_handle := spawn spinner.create(shared spinner_state)

			no_cache := cmd.flags.get_bool('no-cache')!
			c := create_client(use_cache: !no_cache) or { client.new_client(use_cache: !no_cache)! }

			mut results := []client.KbbiResult{}
			for word in cmd.args {
				w_results := c.entry(word) or {
					println('failed to search `${word}`: ${err}')
					exit(1)
				}

				results << w_results
			}

			out := if cmd.flags.get_bool('json')! {
				json.encode(results)
			} else {
				mut tmp := results.map(format_result).join('\n')
				if !cmd.flags.get_bool('no-color')! && term.can_show_color_on_stdout() {
				 	tmp
				} else {
					term.strip_ansi(tmp)
				}
			}

			lock spinner_state {
				spinner_state.done = true
				spinner_handle.wait()
			}

			print(out)
		}
	}

	app.setup()
	app.parse(os.args)
}
