// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	integrations: [
		starlight({
			title: 'The Senior AI Engineering Playbook',
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/withastro/starlight' }],
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
