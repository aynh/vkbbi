module main

import client
import format { format_result }
import os
import term

fn create_client() ?client.KbbiClient {
	return client.new_client_from_login(
		username: os.getenv_opt('KBBI_USERNAME')?
		password: os.getenv_opt('KBBI_PASSWORD')?
	)!
}

fn main() {
	c := create_client() or { client.new_client()! }

	if results := c.entry(os.args[1]) {
		mut out := results.map(format_result).join('\n')
		if !term.can_show_color_on_stdout() {
			out = term.strip_ansi(out)
		}

		print(out)
	} else {
		println(err)
		exit(1)
	}
}
