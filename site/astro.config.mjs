// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	integrations: [
		starlight({
			title: 'The Senior AI Engineering Playbook',
			// Add a `social` entry pointing at the real repository once it has
			// a public home — the previous value was the Starlight placeholder.
			sidebar: [
				{ label: 'Get the book', link: '/pricing/' },
				{
					label: 'Free sample chapters',
					items: [{ autogenerate: { directory: 'handbook' } }],
				},
			],
		}),
	],
});
