<!--
   Copyright 2011 Blue River Interactive

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-->
<plugin>
<name>Solr Search</name>
<package>solr</package>
<directoryFormat>packageOnly</directoryFormat>
<version>0</version>
<loadPriority>5</loadPriority>
<provider>Blue River</provider>
<providerURL>http://blueriver.com</providerURL>
<category>Application</category>
<settings>
	<setting>
		<name>namePrefix</name>
		<label>Prefix added to Solr Collection Name to ensure uniqueness  </label>
		<hint>This determines the prefix of the name that the Solr indexes will have.  By default it will use two indexes per siteID that the plugin is assigned. They are {prefix}{siteid}db and {prefix}{siteid}file</hint>
		<type>text</type>
		<required>false</required>
		<validation></validation>
		<regex></regex>
		<message></message>
		<defaultvalue><cfoutput>#hash("#application.configBean.getPluginDir()#/solr")#</cfoutput></defaultvalue>
		<optionlist></optionlist>
		<optionlabellist></optionlabellist>
	</setting>
	<setting>
		<name>collectionDir</name>
		<label>Collection Directory</label>
		<hint>This is the directory where Mura will create the Solr index if is does not already exist.</hint>
		<type>text</type>
		<required>false</required>
		<validation></validation>
		<regex></regex>
		<message></message>
		<defaultvalue><cfoutput>#application.configBean.getPluginDir()#/solr/collections</cfoutput></defaultvalue>
		<optionlist></optionlist>
		<optionlabellist></optionlabellist>
	</setting>
	<setting>
		<name>createDir</name>
		<label>Auto Create Collection Directory</label>
		<hint>This tells Mura to create the collection directory if it does on already exist.</hint>
		<type>select</type>
		<required>false</required>
		<validation></validation>
		<regex></regex>
		<message></message>
		<defaultvalue>true</defaultvalue>
		<optionlist>true^false</optionlist>
		<optionlabellist></optionlabellist>
	</setting>
</settings>
<eventHandlers>
	<eventHandler event="onApplicationLoad" component="lib.eventHandler" persist="false"/>
</eventHandlers>

<displayobjects location="global"/>
</plugin>
