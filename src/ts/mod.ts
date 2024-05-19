/*
    Automatic code generation for Rover
    Copyright (C) 2024  Andy

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import { loadClasses, pruneClasses, generateType } from './classes.ts';
import { loadEnums } from './enums.ts';

const useNamedTypes = true;

export async function main() {
	const classes = await loadClasses();

	const allowedClasses = [
		'GuiObject',
		'UIAspectRatioConstraint',
		'UIBase',
		'UIComponent',
		'UIConstraint',
		'UICorner',
		'UIFlexItem',
		'UIGradient',
		'UIGridLayout',
		'UIGridStyleLayout',
		'UILayout',
		'UIListLayout',
		'UIPadding',
		'UIPageLayout',
		'UIScale',
		'UISizeConstraint',
		'UIStroke',
		'UITableLayout',
		'UITextSizeConstraint',
	];

	pruneClasses(classes, allowedClasses);

	const enumlist = await loadEnums();

	function getTypeMap(map: Record<string, string>, name: string) {
		const clazz = classes[name];

		for (const properties of clazz.properties || []) {
			map[properties.name.split('.')[1]] = properties.type;
		}

		for (const parent of clazz.inherits || []) {
			if (!useNamedTypes) {
				getTypeMap(map, parent);
			}
		}
	}

	const allTypes: Record<string, Record<string, string>> = {};

	for (const name in classes) {
		const map = {};

		getTypeMap(map, name);

		allTypes[name] = map;
	}

	let src = await Deno.readTextFile('./src/lua/Rover.luau');

	let autogenPortion = `-- BEGIN AUTOGEN\n`;

	autogenPortion += `-- Types\n`;

	const allTypeContents: Record<string, string> = {};

	for (const name in allTypes) {
		autogenPortion += generateType({
			allTypes: allTypes,
			allTypeContents: allTypeContents,
			enumlist: enumlist,
			classes: classes,
			useNamedTypes: useNamedTypes,
			name: name,
		});
	}

	autogenPortion += `-- Code\n`;

	for (const name in allTypes) {
		const renderComments = false;

		if (renderComments) {
			autogenPortion += `-- Renders a ${name} using props and content\n`;

			autogenPortion += `-- \n`;

			autogenPortion +=
				classes[name].description
					.trim()
					.split('\n')
					.map(t => `-- ${t}`)
					.join('\n') + '\n';
		}

		let type = allTypeContents[name];

		if (useNamedTypes) {
			type = `_${name}Props`;
		}

		autogenPortion += `function Rover.${name}(props: ${type}, content: ((elm: ${name}) -> ())?): ()\n`;

		autogenPortion += `\tRover.drawInstance_internal(${JSON.stringify(
			name
		)}, props, content or function() end)\n`;

		autogenPortion += `end\n\n`;
	}

	autogenPortion += `-- END AUTOGEN`;

	src = src.split('-- AUTOGEN').join(autogenPortion);
	src = src
		.split('--!strict\n')
		.join(
			'--!nocheck\n-- Typechecking is disabled due to the sheer number of autogen types\n'
		);
	src = src
		.split('_internal')
		.join('_internal_' + Math.random().toString(16).split('.').join(''));

	await Deno.writeTextFile('./build.luau', src);
}
