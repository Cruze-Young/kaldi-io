function writeKaldiTreeInTextMode(treeFile, tree)
    fp = fopen(treeFile, 'w');
    fprintf(fp, '%s %d %d ToPdf ', tree.ObjectName, ...
        tree.ContextWidth, tree.CentralPosition);
    
    EventMapWrite(fp, tree.root);
    
    fprintf(fp, 'EndContextDependency \n');
end

function fp = EventMapWrite(fp, node)
    if strcmp(node.EventMapType, 'CE')
        fp = ConstantEventMapWrite(fp, node);
    elseif strcmp(node.EventMapType, 'SE')
        fp = SplitEventMapRead(fp, node);
    elseif strcmp(node.EventMapType, 'TE')
        fp = TableEventMapWrite(fp, node);
    end
end

function fp = ConstantEventMapWrite(fp, node)
	fprintf(fp, 'CE %d ', node.pdfID);
end

function fp = TableEventMapWrite(fp, node)
	fprintf(fp, 'TE %d %d ( ', node.Key, node.TableSize);
    for i = 1 : node.TableSize
        fp = EventMapWrite(fp, node.Table{i});
    end
    fprintf(fp, ') \n');
end

function fp = SplitEventMapRead(fp, node)
    fprintf(fp, 'SE %d [ ', node.Key);
    for i = 1 : length(node.YesValueList)
        fprintf(fp, '%d ', node.YesValueList(i));
    end
    fprintf(fp, ']\n');
    
    fprintf(fp, '{ ');
    fp = EventMapWrite(fp, node.YesBranch);
    fp = EventMapWrite(fp, node.NoBranch);
    fprintf(fp, '} \n');
end
