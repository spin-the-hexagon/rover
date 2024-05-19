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

import { ClassObject } from './types.ts';
import * as YAML from 'https://deno.land/std@0.224.0/yaml/mod.ts';
import { classesPath } from './paths.ts';
import { join } from 'https://deno.land/std@0.224.0/path/join.ts';

export async function loadClasses(): Promise<Record<string, ClassObject>> {
	const classes: Record<string, ClassObject> = {};

	for await (const file of Deno.readDir(classesPath)) {
		const path = join(classesPath, file.name);

		const clazz = YAML.parse(await Deno.readTextFile(path)) as ClassObject;

		classes[clazz.name] = clazz;
	}

	return classes;
}

export function pruneClasses(
	classes: Record<string, ClassObject>,
	allowedClasses: string[]
) {
	let updated = true;

	while (updated) {
		updated = false;

		for (const clazz in classes) {
			for (const inherits of classes[clazz].inherits || []) {
				if (allowedClasses.includes(inherits)) {
					if (!allowedClasses.includes(clazz)) {
						allowedClasses.push(clazz);

						updated = true;
					}
				}
			}
		}
	}

	updated = true;

	while (updated) {
		updated = false;

		for (const clazz in classes) {
			for (const inherits of classes[clazz].inherits || []) {
				if (allowedClasses.includes(clazz)) {
					if (!allowedClasses.includes(inherits)) {
						allowedClasses.push(inherits);

						updated = true;
					}
				}
			}
		}
	}

	for (const key in classes) {
		if (!allowedClasses.includes(key)) {
			delete classes[key];
		}
	}
}

export function generateType({ allTypes, allTypeContents, enumlist, classes, useNamedTypes, name }: {
	allTypes: Record<string, Record<string, string>>,
	allTypeContents: Record<string, string>,
	enumlist: string[],
	classes: Record<string, ClassObject>,
	useNamedTypes: boolean,
	name: string
}): string {
	let propMap = `{\n`;

	const properties = [];

	for (const propName in allTypes[name]) {
		let propType = allTypes[name][propName];

		let formattedPropName = propName;

		formattedPropName = formattedPropName.trim();

		if (
			JSON.stringify(formattedPropName) != `"${formattedPropName}"` ||
			formattedPropName.includes(' ')
		) {
			formattedPropName = '[' + JSON.stringify(formattedPropName) + ']';
		}

		const typeMap = {
			bool: 'boolean',
			int: 'number',
			float: 'number',
			int64: 'number',
			UniqueId: 'unknown',
			Content: 'unknown',
			double: 'number',
			QDir: 'unknown',
			QFont: 'unknown',
			BinaryString: 'unknown',
			ProtectedString: 'unknown',
			Path2DControlPoint: 'unknown'
		} as Record<string, string>;

		for (const enm of enumlist) {
			if (enm == "Font") { continue; }
			typeMap[enm] = `Enum.${enm}`;
		}

		if (propType in typeMap) {
			propType = typeMap[propType];
		}

		properties.push(
			`\t${formattedPropName}: ${propType} | Signal<${propType}> | nil`
		);
	}

	propMap += properties.join(',\n');

	propMap += '\n}';

	if (useNamedTypes) {
		for (const parent of classes[name].inherits || []) {
			propMap += ` & _${parent}Props`;
		}
	}

	allTypeContents[name] = propMap;

	if (useNamedTypes) {
		return `type _${name}Props = ${propMap}\n`;
	}

	return '';
}
