# How To Find a Column in a Haystack
I have written a simple PowerShell code which gets a root directory of all my reports and a term I search for. It visits every single PBIX file, renames its extension to ZIP and extracts it. A PBIX file is just a masquerade of a ZIP file. An unzipped file is a directory. In this directory, I am interested in the file *Report/Layout*, which contains report’s own measures and a definition of all pages. 

Let’s take a look at the file internals. It is a JSON file which you can open in a text editor and format it. The red box on the screenshot below is a definition of a report’s page. The green one contains a definition of measures defined in this report. If I go back to the red box, there are other two colorful boxes. The blue one contains visuals of the page and the purple one contains filters. 

![img](https://github.com/nolockcz/PowerPlatform/raw/master/Search%20for%20a%20Column%20in%20PBIX%20Files/readme%20images/2.png)

In my use case, I don’t care about this level of detail. In the vast majority of cases, it is enough to have a list of file names using a column.

## The original blog post
The code is a part of a blog post: https://community.powerbi.com/t5/Community-Blog/How-To-Find-a-Column-in-a-Haystack/ba-p/893869
