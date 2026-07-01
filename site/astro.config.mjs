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
				{ label: 'The Handbook', items: [{ autogenerate: { directory: 'handbook' } }] },
				{ label: 'Prompt Library', items: [{ autogenerate: { directory: 'prompts' } }] },
				{ label: 'ADRs', items: [{ autogenerate: { directory: 'adrs' } }] },
				{
					label: 'Architecture Breakdowns',
					items: [{ autogenerate: { directory: 'architecture-breakdowns' } }],
				},
				{
					label: 'Interview Playbooks',
					items: [{ autogenerate: { directory: 'interview-playbooks' } }],
				},
				{ label: 'Sample Apps', items: [{ autogenerate: { directory: 'sample-apps' } }] },
				{ label: 'Templates', items: [{ autogenerate: { directory: 'templates' } }] },
			],
		}),
	],
});
