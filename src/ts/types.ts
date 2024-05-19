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

export interface ClassObject {
    /**
     * A list of callbacks. Each entry has the same keys. Table list. Automated.
     */
    callbacks: Callback[] | null;
    /**
     * General category of the class.
     */
    category: null | string;
    /**
     * A list of code samples for the class. String list.
     */
    code_samples: string[] | null;
    /**
     * Description of why the class is deprecated and what to use instead.
     */
    deprecation_message: string;
    /**
     * A long description of how the class operates. Markdown.
     */
    description: string;
    /**
     * A list of events. Each entry has the same keys. Table list. Automated.
     */
    events: Event[] | null;
    /**
     * Defines which classes this class inherits from. String list.
     */
    inherits: string[] | null;
    /**
     * Defines where the class appears in the Memory tab of the Developer Console. Automated.
     */
    memory_category: null | string;
    /**
     * A list of methods. Each entry has the same keys. Table list. Automated.
     */
    methods: Method[] | null;
    /**
     * The name of the class. Determines the name of the page. Used for automatic cross-linking.
     * String. Automated.
     */
    name: string;
    /**
     * A list of properties. Each entry has the same keys. Table list. Automated.
     */
    properties: Property[] | null;
    /**
     * A single sentence overview of this class. Used in hover menus and suggestions. String.
     */
    summary: string;
    tags:    Tag[] | null;
    /**
     * the type of the API (class, datatype, enum, global, library). Automated.
     */
    type: Type;
    [property: string]: any;
}

export interface Callback {
    /**
     * A list of code samples for the callback. String list.
     */
    code_samples: string[] | null;
    /**
     * Description of why the callback is deprecated and what to use instead. String.
     */
    deprecation_message: string;
    /**
     * A long description of the callback. String.
     */
    description: string;
    /**
     * The name of the callback. String. Automated.
     */
    name:       string;
    parameters: Parameter[] | null;
    returns:    Return[] | null;
    /**
     * Security tag for this callback. String. Automated.
     */
    security: SecurityEnum;
    /**
     * A single sentence overview of the callback. String.
     */
    summary:       string;
    tags:          Tag[] | null;
    thread_safety: ThreadSafety;
    [property: string]: any;
}

/**
 * Parameters of this item. Each entry has the same keys. Table list. Automated.
 */
export interface Parameter {
    /**
     * The default value of the parameter. Any. Automated.
     */
    default: boolean | number | { [key: string]: any } | null | string;
    /**
     * Name of the parameter. String. Automated.
     */
    name: string;
    /**
     * A single sentence definition of the parameter. String.
     */
    summary: string;
    /**
     * The datatype of the parameter. String. Automated.
     */
    type: string;
    [property: string]: any;
}

/**
 * Returns of this item. Each entry has the same keys. Table list. Automated.
 */
export interface Return {
    /**
     * A single sentence definition of the return. String.
     */
    summary: string;
    /**
     * The datatype of the return. String. Automated.
     */
    type: null | string;
    [property: string]: any;
}

/**
 * Security tag for this item. Enum. Automated.
 */
export enum SecurityEnum {
    LocalUserSecurity = "LocalUserSecurity",
    None = "None",
    NotAccessibleSecurity = "NotAccessibleSecurity",
    PluginSecurity = "PluginSecurity",
    RobloxScriptSecurity = "RobloxScriptSecurity",
    RobloxSecurity = "RobloxSecurity",
}

/**
 * Tags for this item, such as Deprecated. String list. Automated.
 */
export enum Tag {
    CanYield = "CanYield",
    CustomLuaState = "CustomLuaState",
    Deprecated = "Deprecated",
    Hidden = "Hidden",
    NoYield = "NoYield",
    NotBrowsable = "NotBrowsable",
    NotCreatable = "NotCreatable",
    NotReplicated = "NotReplicated",
    NotScriptable = "NotScriptable",
    PlayerReplicated = "PlayerReplicated",
    ReadOnly = "ReadOnly",
    Service = "Service",
    Settings = "Settings",
    UserSettings = "UserSettings",
    Yields = "Yields",
}

/**
 * Thread safety of this item. Enum. Automated.
 */
export enum ThreadSafety {
    ReadOnly = "ReadOnly",
    ReadSafe = "ReadSafe",
    Safe = "Safe",
    Unsafe = "Unsafe",
}

export interface Event {
    /**
     * A list of code samples for the event. String list.
     */
    code_samples: string[] | null;
    /**
     * Description of why the event is deprecated and what to use instead. String.
     */
    deprecation_message: string;
    /**
     * A long description of the event. String.
     */
    description: string;
    /**
     * The name of the event. String. Automated.
     */
    name:       string;
    parameters: Parameter[] | null;
    /**
     * Security tag for this event. String. Automated.
     */
    security: SecurityEnum;
    /**
     * A single sentence overview of the event. String.
     */
    summary:       string;
    tags:          Tag[] | null;
    thread_safety: ThreadSafety;
    [property: string]: any;
}

export interface Method {
    /**
     * A list of code samples for the method. String list.
     */
    code_samples: string[] | null;
    /**
     * Description of why the method is deprecated and what to use instead. String.
     */
    deprecation_message: string;
    /**
     * A long description of the method. String.
     */
    description: string;
    /**
     * The name of the method. String. Automated.
     */
    name:       string;
    parameters: Parameter[] | null;
    returns:    Return[] | null;
    /**
     * Security tag for this method. String. Automated.
     */
    security: SecurityEnum;
    /**
     * A single sentence overview of the method. String.
     */
    summary:       string;
    tags:          Tag[] | null;
    thread_safety: ThreadSafety;
    [property: string]: any;
}

export interface Property {
    /**
     * The name of the category that this property appears under in the Properties window in
     * Studio. Automated.
     */
    category: string;
    /**
     * A list of code samples for the property. String list.
     */
    code_samples: string[] | null;
    /**
     * Description of why the property is deprecated and what to use instead. String.
     */
    deprecation_message: string;
    /**
     * A long description of the property. String.
     */
    description: string;
    /**
     * The name of the property. String. Automated.
     */
    name: string;
    /**
     * Security tags for this property. Automated.
     */
    security: SecurityObject;
    /**
     * Serialization for this property. Object. Automated.
     */
    serialization: Serialization;
    /**
     * A single sentence overview of the property. String.
     */
    summary:       string;
    tags:          Tag[] | null;
    thread_safety: ThreadSafety;
    /**
     * The data type of the property. string. Automated.
     */
    type: string;
    [property: string]: any;
}

/**
 * Security tags for this property. Automated.
 */
export interface SecurityObject {
    /**
     * The read security tag for this property. String. Automated.
     */
    read: SecurityEnum;
    /**
     * The write security tag for this property. String. Automated.
     */
    write: SecurityEnum;
    [property: string]: any;
}

/**
 * Serialization for this property. Object. Automated.
 */
export interface Serialization {
    /**
     * The read security tag for this property. String. Automated.
     */
    can_load: boolean;
    /**
     * The write security tag for this property. String. Automated.
     */
    can_save: boolean;
    [property: string]: any;
}

/**
 * the type of the API (class, datatype, enum, global, library). Automated.
 */
export enum Type {
    Class = "class",
}

export interface EnumObject {
    /**
     * List of code samples for the enum. String list.
     */
    code_samples:        string[] | null;
    deprecation_message: string;
    /**
     * Longer description of how the enum operates. Markdown.
     */
    description: string;
    /**
     * List of enum items associated with enum. Each entry has the same keys. Table list.
     * Automated.
     */
    items: Item[];
    /**
     * The name of the enum. Determines the name of the page. Used for automatic cross-linking.
     * String. Automated.
     */
    name: string;
    /**
     * A single sentence overview of enum. Used in hover menus and suggestions. String.
     */
    summary: string;
    tags:    Tag[] | null;
    /**
     * the type of the API (class, datatype, enum, global, library). Automated.
     */
    type: Type;
    [property: string]: any;
}

export interface Item {
    deprecation_message: string;
    /**
     * The name of the enum item. String. Automated.
     */
    name: string;
    /**
     * A single sentence overview of the enum item. String.
     */
    summary: string;
    tags:    Tag[] | null;
    /**
     * The value of the enum item. Integer. Automated.
     */
    value: number;
    [property: string]: any;
}
