// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	integrations: [
		starlight({
			title: 'The Senior AI Engineering Playbook',
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/gurpreet-ios/ios-ai-playbook' },
			],
			sidebar: [
				{
					label: 'Handbook',
					items: [{ autogenerate: { directory: 'handbook' } }],
				},
				{ label: 'GitHub repo', link: 'https://github.com/gurpreet-ios/ios-ai-playbook' },
			],
		}),
	],
});
