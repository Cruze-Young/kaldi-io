function tree = readKaldiTreeInTextMode(treeFile)
    fp = fopen(treeFile, 'r');
    content = {};
    while ~feof(fp)
        line = fgetl(fp);
        tmp = strsplit(line, ' ');
        content = [content, tmp];
    end
    
    tree.ObjectName = content{1};
    tree.ContextWidth = str2double(content(2));
    tree.CentralPosition = str2double(content(3));
    
    idx = 5;
    tree.root = EventMapRead(content, idx);
    
end


function [node, idx] = EventMapRead(content, idx)
    if strcmp(content(idx), 'SE')
        [node, idx] = SplitEventMapRead(content, idx + 1);
    elseif strcmp(content(idx), 'CE')
        [node, idx] = ConstantEventMapRead(content, idx + 1);
    elseif strcmp(content(idx), 'TE')
        [node, idx] = TableEventMapRead(content, idx + 1);
    end
    
end

function [node, idx] = ConstantEventMapRead(content, idx)
    node.EventMapType = 'CE';
    node.pdfID = str2double(content(idx));
    idx = idx + 1;
end

function [node, idx] = TableEventMapRead(content, idx)
    node.EventMapType = 'TE';
    node.Key = str2double(content(idx));
    
    idx = idx + 1;
    node.TableSize = str2double(content(idx));
    
    idx = idx + 2;
    node.Table = cell(node.TableSize, 1);
    for i = 1 : node.TableSize
        [node.Table{i}, idx] = EventMapRead(content, idx);
    end
    idx = idx + 1;
end

function [node, idx] = SplitEventMapRead(content, idx)
    node.EventMapType = 'SE';
    node.Key = str2double(content(idx));
    idx = idx + 2;
    idx2 = idx;
    while ~strcmp(content(idx2), ']')
        idx2 = idx2 + 1;
    end
    node.YesValueList = str2double(content(idx : idx2-1));
    idx = idx2 + 1;
    
    if strcmp(content(idx), '{')
        idx = idx + 1;
    end
    [node.YesBranch, idx] = EventMapRead(content, idx);
    [node.NoBranch, idx] = EventMapRead(content, idx);
    if strcmp(content(idx), '}')
        idx = idx + 1;
    end
    if strcmp(content(idx), '')
        idx = idx + 1;
    end
end
